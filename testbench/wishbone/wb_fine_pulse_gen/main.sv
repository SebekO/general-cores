//------------------------------------------------------------------------------
// Copyright CERN 2018
//------------------------------------------------------------------------------
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0.
// Unless required by applicable law or agreed to in writing, software,
// hardware and materials distributed under this License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied. See the License for the specific language governing permissions
// and limitations under the License.
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ps / 1ps

`include "vhd_wishbone_master.svh"

`include "glbl.v"

import gencores_sim_pkg::*;
import wb_fpgen_regs_Consts::*;

class FinePulseGenDriver extends CBusDevice;

  protected int m_use_delayctrl = 1;
  protected real m_coarse_range = 16.0;
  protected real m_delay_tap_size = 0.078;  /*ns*/
  protected int m_fine_taps;
  protected LoggerClient m_log;
  protected bit m_with_odelay;
  protected int m_serdes_ratio;
  protected real m_serdes_bit_length_ns;

  function new(CBusAccessor acc, int base, bit with_odelay);
    super.new(acc, base);
    m_log = new;
    m_with_odelay = with_odelay;
  endfunction  // new

  protected task automatic poll_bits_with_timeout(input uint32_t addr, uint32_t mask,
                                                  uint32_t expected_value, time timeout,
                                                  output uint32_t result, output bit fail);
    time t_start = $time;

    while ($time - t_start < timeout) begin
      uint32_t rv;
      readl(addr, rv);
      //$display("RD %x %x mask %x", addr, rv, mask);
      result = rv & mask;
      if ((rv & mask) == expected_value) begin
        fail = 0;
        return;
      end
    end

    fail = 1;
  endtask


  task automatic calibrate_kintexu();
    uint32_t rv;
    bit fail;
    real calib_time;
    int calib_taps;

    m_log.msg(0, "ODELAY Calibration start [KintexUltrascale]");

    m_serdes_ratio = 16;
    m_serdes_bit_length_ns = 1.0;

    poll_bits_with_timeout(ADDR_WB_FPGEN_CSR, WB_FPGEN_CSR_PLL_LOCKED, WB_FPGEN_CSR_PLL_LOCKED,
                           20us, rv, fail);

    if (fail) begin
      m_log.fail("Timeout exceeded waiting for PLL_LOCKED bit.");
      return;
    end

    writel(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_EN_VTC);
    writel(ADDR_WB_FPGEN_ODELAY_CALIB,
           WB_FPGEN_ODELAY_CALIB_RST_IDELAYCTRL  |  WB_FPGEN_ODELAY_CALIB_RST_OSERDES | WB_FPGEN_ODELAY_CALIB_RST_ODELAY);
    #100ns;
    writel(ADDR_WB_FPGEN_ODELAY_CALIB,
           WB_FPGEN_ODELAY_CALIB_RST_IDELAYCTRL | WB_FPGEN_ODELAY_CALIB_RST_OSERDES);
    #100ns;
    writel(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_RST_IDELAYCTRL);
    #100ns;
    writel(ADDR_WB_FPGEN_ODELAY_CALIB, 0);
    #100ns;

    poll_bits_with_timeout(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_RDY, WB_FPGEN_ODELAY_CALIB_RDY,
                           20us, rv, fail);

    if (fail) begin
      m_log.fail("Timeout exceeded waiting for CALIB_RDY bit.");
      return;
    end

    writel(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_CAL_LATCH);
    #1us;
    readl(ADDR_WB_FPGEN_ODELAY_CALIB, rv);

    calib_time = real'(1.0);
    calib_taps = (rv & WB_FPGEN_ODELAY_CALIB_TAPS) >> WB_FPGEN_ODELAY_CALIB_TAPS_OFFSET;

    m_log.msg(0, $sformatf(
              "FPGen ODELAYE3 calibration done, r %x %.1f ns = %d taps\n", rv, calib_time, calib_taps));

    m_delay_tap_size = calib_time / real'(calib_taps);
  endtask

  task automatic calibrate_kintex7();
    uint32_t rv;
    bit fail;
    real calib_time;
    int calib_taps;

    m_serdes_ratio = 8;
    m_serdes_bit_length_ns = 2.0;

    m_log.msg(0, "ODELAY Calibration start [Kintex7]");

    writel(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_RST_IDELAYCTRL);
    writel(ADDR_WB_FPGEN_ODELAY_CALIB, 0);

    writel(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_RST_OSERDES);
    #1us;
    writel(ADDR_WB_FPGEN_ODELAY_CALIB, 0);
    #1us;


    if (!m_with_odelay) return;

    poll_bits_with_timeout(ADDR_WB_FPGEN_ODELAY_CALIB, WB_FPGEN_ODELAY_CALIB_RDY, WB_FPGEN_ODELAY_CALIB_RDY,
                           20us, rv, fail);

    if (fail) begin
      m_log.fail("Timeout exceeded waiting for CALIB_RDY bit.");
      return;
    end

    m_delay_tap_size = 0.078;  /* nanoseconds, default value for Kintex7 */

  endtask


  task automatic pulse(int out, int polarity, int cont, real delta, real length = 0,
                       int tr_force = 0);
    uint32_t rv;
    bit fail;

    real coarse_range = m_serdes_bit_length_ns * m_serdes_ratio;

    int coarse_par = int'($floor(delta / coarse_range));
    int coarse_ser = int'($floor(delta / m_serdes_bit_length_ns) - coarse_par * m_serdes_ratio);
    int fine = int'((delta / m_serdes_bit_length_ns - $floor(
        delta / m_serdes_bit_length_ns
    )) * m_serdes_bit_length_ns / m_delay_tap_size);
    int len_tics = int'(length / m_coarse_range / 16.0);
    uint32_t ocr_a, ocr_b;

    if (!m_with_odelay) fine = 0;

    m_log.msg(1, $sformatf(
              "Pulse: tap_size %.5f coarse_par %d coarse_ser %d fine_taps %d length %.0f len_tics %d",
              m_delay_tap_size,
              coarse_par,
              coarse_ser,
              fine,
              length,
              len_tics
              ));

  ocr_a = (coarse_ser << WB_FPGEN_OCR0A_COARSE_OFFSET)
      | (fine << WB_FPGEN_OCR0A_FINE_OFFSET)
      | (cont ? WB_FPGEN_OCR0A_CONT : 0)
      | (polarity ? WB_FPGEN_OCR0A_POL : 0 );

    ocr_b = (coarse_par << WB_FPGEN_OCR0B_PPS_OFFS_OFFSET)
	    | (len_tics << WB_FPGEN_OCR0B_LENGTH_OFFSET);



    writel(ADDR_WB_FPGEN_OCR0A + 8 * out, ocr_a);
    writel(ADDR_WB_FPGEN_OCR0B + 8 * out, ocr_b);

    if (tr_force)
      writel(ADDR_WB_FPGEN_CSR, 1 << (WB_FPGEN_CSR_FORCE0_OFFSET + out));
    else
      writel(ADDR_WB_FPGEN_CSR, 1 << (WB_FPGEN_CSR_TRIG0_OFFSET + out));

    #100ns;

    poll_bits_with_timeout(ADDR_WB_FPGEN_CSR, (1 << (WB_FPGEN_CSR_READY_OFFSET + out)),
                           (1 << (WB_FPGEN_CSR_READY_OFFSET + out)), 20us, rv, fail);

    if (fail) begin
      m_log.fail("Timeout exceeded waiting for channel trigger ready bit.");
    end


  endtask


endclass  // FinePulseGenDriver


module fpgen_test_wrapper;

  parameter string g_TARGET_PLATFORM = "KintexUltrascale";

  reg rst_n = 0;
  reg clk_125m = 0;
  reg clk_250m = 0;
  reg clk_62m5 = 0;
  reg clk_dmtd = 0;

  always #2ns clk_250m <= ~clk_250m;
  always @(posedge clk_250m) clk_125m <= ~clk_125m;
  always #(7.9ns) clk_dmtd <= ~clk_dmtd;
  always @(posedge clk_125m) clk_62m5 <= ~clk_62m5;

  time t_pps;
  bit  t_pps_valid = 1'b0;

  initial begin
    repeat (20) @(posedge clk_125m);
    rst_n = 1;
  end



  reg pps_p = 0;


  real timestamps_expected[$], timestamps_measured[$];
  real widths_expected[$], widths_measured[$];

  wire [0:0] pulses;

  IVHDWishboneMaster Host (
      .clk_i  (clk_62m5),
      .rst_n_i(rst_n)
  );

  // the Device Under Test
  xwb_fine_pulse_gen #(
      .g_target_platform(g_TARGET_PLATFORM),
      .g_use_external_serdes_clock(0),
      .g_num_channels(1),
      .g_use_odelay(6'b111111)
  ) DUT (
      .rst_sys_n_i(rst_n),

      //      .clk_ser_ext_i(clk_250m),
      .clk_sys_i(clk_62m5),
      .clk_ref_i(clk_62m5),

      .pps_p_i(pps_p),

      .pulse_o(pulses),

      .slave_i(Host.out),
      .slave_o(Host.in)
  );


  always @(posedge pps_p) begin
    t_pps = $time;
    t_pps_valid = 1;
  end

  initial
    forever begin
      repeat (100) @(posedge clk_62m5);
      pps_p <= 1;
      @(posedge clk_62m5);
      pps_p <= 0;
      #1us;
    end

  function automatic bit within_tollerance(real x, real y, real tollerance);
    if (x < y) return (y - x) < tollerance;
    else return (x - y) < tollerance;
  endfunction

  function automatic int compare_timestamps(real tollerance = 0.1);
    Logger logger = Logger::get();
    int i;

    if (timestamps_expected.size() != timestamps_measured.size()) begin
      logger.fail($sformatf(
                  "Asked for %d pulses but got %d timestamps.",
                  timestamps_expected.size(),
                  timestamps_measured.size()
                  ));
      return -1;
    end

    if (widths_expected.size() != widths_measured.size()) begin
      logger.fail($sformatf(
                  "Asked for %d pulse widths measurements but got %d measurements.",
                  widths_expected.size(),
                  widths_measured.size()
                  ));
      return -1;
    end

    for (i = 0; i < timestamps_measured.size(); i++) begin
      automatic real dt = timestamps_measured[i] - timestamps_expected[i];
      automatic real dtw = widths_measured[i] - widths_expected[i];

      logger.msg(2, $sformatf(
                 "Measured TS %.03f ns, expected %.03f ns, delta %03f ns",
                 timestamps_measured[i],
                 timestamps_expected[i],
                 dt
                 ));
      logger.msg(2, $sformatf(
                 "Measured Width %.03f ns, expected %.03f ns, delta %03f ns",
                 widths_measured[i],
                 widths_expected[i],
                 dtw
                 ));

      if (!within_tollerance(timestamps_measured[i], timestamps_expected[i], tollerance)) begin
        logger.fail($sformatf(
                    "Expected and measured timestamps differ by more than %.03f ns", tollerance));
        return -1;
      end

      if (!within_tollerance(widths_measured[i], widths_expected[i], tollerance)) begin
        logger.fail($sformatf(
                    "Expected and measured pulse width differ by more than %.03f ns", tollerance));
        return -1;
      end
    end
    return 0;
  endfunction

  task automatic clear_timestamps();
    timestamps_expected = '{};
    timestamps_measured = '{};
    widths_expected = '{};
    widths_measured = '{};

  endtask

  task run_tests();
    real t;
    real pwidths[$];
    Logger logger = Logger::get();
    CWishboneAccessor acc;
    FinePulseGenDriver drv;

    @(posedge rst_n);
    @(posedge clk_62m5);


    acc = Host.get_accessor();
    acc.set_mode(PIPELINED);

    drv = new(acc, 0, 1);

    logger.startTest($sformatf("Run calibration [%s]", g_TARGET_PLATFORM));

    if (g_TARGET_PLATFORM == "KintexUltrascale") drv.calibrate_kintexu();
    else drv.calibrate_kintex7();

    logger.pass();


    logger.startTest(
        $sformatf("Produce some fixed-width pulses at fine PPS offsets [%s]", g_TARGET_PLATFORM));

    clear_timestamps();
    for (t = 1.0; t <= 1.0; t += 5) begin
      t_pps_valid = 0;
      while (!t_pps_valid) @(posedge clk_62m5);
      $warning("dupa!");
      //logger.msg(1, $sformatf("PPS absolute time = %t", t_pps));
      logger.msg(1, $sformatf("Ts Expected = %.03f", t));
      timestamps_expected.push_back(t + 108.7);
      widths_expected.push_back(1088.0);
      drv.pulse(0, 0, 1, t, 1088.0);
    end

    if (!compare_timestamps()) logger.pass();

    $stop;

    logger.startTest(
        $sformatf("Produce some variable-width pulses at fixed PPS offsets [%s]", g_TARGET_PLATFORM
        ));
    clear_timestamps();

    pwidths.push_back(8.0);
    for (t = 320.0; t <= 3000.0; t += 256.0) pwidths.push_back(t);

    foreach (pwidths[i]) begin
      t_pps_valid = 0;
      while (!t_pps_valid) @(posedge clk_62m5);

      timestamps_expected.push_back(108.7);

      widths_expected.push_back(pwidths[i]);
      drv.pulse(0, 0, 0, 0, pwidths[i]);
    end

    if (!compare_timestamps()) logger.pass();


  endtask

  time t_last;

  always @(posedge pulses[0]) begin
    automatic Logger logger = Logger::get();
    automatic real   timestamp = real'(($time - t_pps) / 1ns);
    logger.msg(2, $sformatf("Pulse @ %.3f ns", timestamp));
    t_last <= $time;
    timestamps_measured.push_back(timestamp);
  end

  always @(negedge pulses[0]) begin
    automatic real   d = real'(($time - t_last) / 1ns);
    automatic Logger logger = Logger::get();
    logger.msg(2, $sformatf("Width @ %.3f ns", d));
    widths_measured.push_back(d);
  end


endmodule


module main;

  fpgen_test_wrapper #(.g_TARGET_PLATFORM("Kintex7")) DUT_K7 ();
  //fpgen_test_wrapper #(.g_TARGET_PLATFORM("KintexUltrascale")) DUT_KU ();

  initial begin
    Logger logger = Logger::get();

    DUT_K7.run_tests();
    //DUT_KU.run_tests();

    logger.writeTestReport(1, 1);
    $stop;
  end

endmodule  // main
