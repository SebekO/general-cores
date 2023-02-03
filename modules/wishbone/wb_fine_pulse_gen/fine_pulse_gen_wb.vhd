-- Do not edit.  Generated by cheby 1.5.dev0 using these options:
--  -i fine_pulse_gen_wb.cheby --gen-hdl fine_pulse_gen_wb.vhd
-- Generated on Tue Dec 20 23:28:33 2022 by twl


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

package fine_pulse_gen_wb_pkg is
  type t_fpgen_regs_master_out is record
    csr_TRIG0        : std_logic;
    csr_TRIG1        : std_logic;
    csr_TRIG2        : std_logic;
    csr_TRIG3        : std_logic;
    csr_TRIG4        : std_logic;
    csr_TRIG5        : std_logic;
    csr_TRIG6        : std_logic;
    csr_TRIG7        : std_logic;
    csr_FORCE0       : std_logic;
    csr_FORCE1       : std_logic;
    csr_FORCE2       : std_logic;
    csr_FORCE3       : std_logic;
    csr_FORCE4       : std_logic;
    csr_FORCE5       : std_logic;
    csr_READY        : std_logic_vector(5 downto 0);
    csr_PLL_RST      : std_logic;
    csr_SERDES_RST   : std_logic;
    csr_PLL_LOCKED   : std_logic;
    OCR0A_FINE       : std_logic_vector(11 downto 0);
    OCR0A_POL        : std_logic;
    OCR0A_COARSE     : std_logic_vector(4 downto 0);
    OCR0A_CONT       : std_logic;
    OCR0A_TRIG_SEL   : std_logic;
    OCR0B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR0B_LENGTH     : std_logic_vector(15 downto 0);
    OCR1A_FINE       : std_logic_vector(11 downto 0);
    OCR1A_POL        : std_logic;
    OCR1A_COARSE     : std_logic_vector(4 downto 0);
    OCR1A_CONT       : std_logic;
    OCR1A_TRIG_SEL   : std_logic;
    OCR1B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR1B_LENGTH     : std_logic_vector(15 downto 0);
    OCR2A_FINE       : std_logic_vector(11 downto 0);
    OCR2A_POL        : std_logic;
    OCR2A_COARSE     : std_logic_vector(4 downto 0);
    OCR2A_CONT       : std_logic;
    OCR2A_TRIG_SEL   : std_logic;
    OCR2B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR2B_LENGTH     : std_logic_vector(15 downto 0);
    OCR3A_FINE       : std_logic_vector(11 downto 0);
    OCR3A_POL        : std_logic;
    OCR3A_COARSE     : std_logic_vector(4 downto 0);
    OCR3A_CONT       : std_logic;
    OCR3A_TRIG_SEL   : std_logic;
    OCR3B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR3B_LENGTH     : std_logic_vector(15 downto 0);
    OCR4A_FINE       : std_logic_vector(11 downto 0);
    OCR4A_POL        : std_logic;
    OCR4A_COARSE     : std_logic_vector(4 downto 0);
    OCR4A_CONT       : std_logic;
    OCR4A_TRIG_SEL   : std_logic;
    OCR4B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR4B_LENGTH     : std_logic_vector(15 downto 0);
    OCR5A_FINE       : std_logic_vector(11 downto 0);
    OCR5A_POL        : std_logic;
    OCR5A_COARSE     : std_logic_vector(4 downto 0);
    OCR5A_CONT       : std_logic;
    OCR5A_TRIG_SEL   : std_logic;
    OCR5B_PPS_OFFS   : std_logic_vector(15 downto 0);
    OCR5B_LENGTH     : std_logic_vector(15 downto 0);
    odelay_calib_rst_idelayctrl : std_logic;
    odelay_calib_rst_odelay : std_logic;
    odelay_calib_rst_oserdes : std_logic;
    odelay_calib_rdy : std_logic;
    odelay_calib_value : std_logic_vector(8 downto 0);
    odelay_calib_value_update : std_logic;
    odelay_calib_en_vtc : std_logic;
    odelay_calib_cal_latch : std_logic;
    odelay_calib_taps : std_logic_vector(8 downto 0);
  end record t_fpgen_regs_master_out;
  subtype t_fpgen_regs_slave_in is t_fpgen_regs_master_out;

  type t_fpgen_regs_slave_out is record
    csr_READY        : std_logic_vector(5 downto 0);
    csr_PLL_LOCKED   : std_logic;
    odelay_calib_rdy : std_logic;
    odelay_calib_value : std_logic_vector(8 downto 0);
    odelay_calib_taps : std_logic_vector(8 downto 0);
  end record t_fpgen_regs_slave_out;
  subtype t_fpgen_regs_master_in is t_fpgen_regs_slave_out;

end fine_pulse_gen_wb_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.fine_pulse_gen_wb_pkg.all;

entity fine_pulse_gen_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;
    -- Wires and registers
    fpgen_regs_i         : in    t_fpgen_regs_master_in;
    fpgen_regs_o         : out   t_fpgen_regs_master_out
  );
end fine_pulse_gen_wb;

architecture syn of fine_pulse_gen_wb is
  signal adr_int                        : std_logic_vector(5 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal csr_TRIG0_reg                  : std_logic;
  signal csr_TRIG1_reg                  : std_logic;
  signal csr_TRIG2_reg                  : std_logic;
  signal csr_TRIG3_reg                  : std_logic;
  signal csr_TRIG4_reg                  : std_logic;
  signal csr_TRIG5_reg                  : std_logic;
  signal csr_TRIG6_reg                  : std_logic;
  signal csr_TRIG7_reg                  : std_logic;
  signal csr_FORCE0_reg                 : std_logic;
  signal csr_FORCE1_reg                 : std_logic;
  signal csr_FORCE2_reg                 : std_logic;
  signal csr_FORCE3_reg                 : std_logic;
  signal csr_FORCE4_reg                 : std_logic;
  signal csr_FORCE5_reg                 : std_logic;
  signal csr_PLL_RST_reg                : std_logic;
  signal csr_SERDES_RST_reg             : std_logic;
  signal csr_wreq                       : std_logic;
  signal csr_wack                       : std_logic;
  signal OCR0A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR0A_POL_reg                  : std_logic;
  signal OCR0A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR0A_CONT_reg                 : std_logic;
  signal OCR0A_TRIG_SEL_reg             : std_logic;
  signal OCR0A_wreq                     : std_logic;
  signal OCR0A_wack                     : std_logic;
  signal OCR0B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR0B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR0B_wreq                     : std_logic;
  signal OCR0B_wack                     : std_logic;
  signal OCR1A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR1A_POL_reg                  : std_logic;
  signal OCR1A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR1A_CONT_reg                 : std_logic;
  signal OCR1A_TRIG_SEL_reg             : std_logic;
  signal OCR1A_wreq                     : std_logic;
  signal OCR1A_wack                     : std_logic;
  signal OCR1B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR1B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR1B_wreq                     : std_logic;
  signal OCR1B_wack                     : std_logic;
  signal OCR2A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR2A_POL_reg                  : std_logic;
  signal OCR2A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR2A_CONT_reg                 : std_logic;
  signal OCR2A_TRIG_SEL_reg             : std_logic;
  signal OCR2A_wreq                     : std_logic;
  signal OCR2A_wack                     : std_logic;
  signal OCR2B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR2B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR2B_wreq                     : std_logic;
  signal OCR2B_wack                     : std_logic;
  signal OCR3A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR3A_POL_reg                  : std_logic;
  signal OCR3A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR3A_CONT_reg                 : std_logic;
  signal OCR3A_TRIG_SEL_reg             : std_logic;
  signal OCR3A_wreq                     : std_logic;
  signal OCR3A_wack                     : std_logic;
  signal OCR3B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR3B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR3B_wreq                     : std_logic;
  signal OCR3B_wack                     : std_logic;
  signal OCR4A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR4A_POL_reg                  : std_logic;
  signal OCR4A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR4A_CONT_reg                 : std_logic;
  signal OCR4A_TRIG_SEL_reg             : std_logic;
  signal OCR4A_wreq                     : std_logic;
  signal OCR4A_wack                     : std_logic;
  signal OCR4B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR4B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR4B_wreq                     : std_logic;
  signal OCR4B_wack                     : std_logic;
  signal OCR5A_FINE_reg                 : std_logic_vector(11 downto 0);
  signal OCR5A_POL_reg                  : std_logic;
  signal OCR5A_COARSE_reg               : std_logic_vector(4 downto 0);
  signal OCR5A_CONT_reg                 : std_logic;
  signal OCR5A_TRIG_SEL_reg             : std_logic;
  signal OCR5A_wreq                     : std_logic;
  signal OCR5A_wack                     : std_logic;
  signal OCR5B_PPS_OFFS_reg             : std_logic_vector(15 downto 0);
  signal OCR5B_LENGTH_reg               : std_logic_vector(15 downto 0);
  signal OCR5B_wreq                     : std_logic;
  signal OCR5B_wack                     : std_logic;
  signal odelay_calib_rst_idelayctrl_reg : std_logic;
  signal odelay_calib_rst_odelay_reg    : std_logic;
  signal odelay_calib_rst_oserdes_reg   : std_logic;
  signal odelay_calib_value_update_reg  : std_logic;
  signal odelay_calib_en_vtc_reg        : std_logic;
  signal odelay_calib_cal_latch_reg     : std_logic;
  signal odelay_calib_wreq              : std_logic;
  signal odelay_calib_wack              : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(5 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb_i.dat;
      end if;
    end if;
  end process;

  -- Register csr
  fpgen_regs_o.csr_TRIG0 <= csr_TRIG0_reg;
  fpgen_regs_o.csr_TRIG1 <= csr_TRIG1_reg;
  fpgen_regs_o.csr_TRIG2 <= csr_TRIG2_reg;
  fpgen_regs_o.csr_TRIG3 <= csr_TRIG3_reg;
  fpgen_regs_o.csr_TRIG4 <= csr_TRIG4_reg;
  fpgen_regs_o.csr_TRIG5 <= csr_TRIG5_reg;
  fpgen_regs_o.csr_TRIG6 <= csr_TRIG6_reg;
  fpgen_regs_o.csr_TRIG7 <= csr_TRIG7_reg;
  fpgen_regs_o.csr_FORCE0 <= csr_FORCE0_reg;
  fpgen_regs_o.csr_FORCE1 <= csr_FORCE1_reg;
  fpgen_regs_o.csr_FORCE2 <= csr_FORCE2_reg;
  fpgen_regs_o.csr_FORCE3 <= csr_FORCE3_reg;
  fpgen_regs_o.csr_FORCE4 <= csr_FORCE4_reg;
  fpgen_regs_o.csr_FORCE5 <= csr_FORCE5_reg;
  fpgen_regs_o.csr_READY <= wr_dat_d0(19 downto 14);
  fpgen_regs_o.csr_PLL_RST <= csr_PLL_RST_reg;
  fpgen_regs_o.csr_SERDES_RST <= csr_SERDES_RST_reg;
  fpgen_regs_o.csr_PLL_LOCKED <= wr_dat_d0(22);
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        csr_TRIG0_reg <= '0';
        csr_TRIG1_reg <= '0';
        csr_TRIG2_reg <= '0';
        csr_TRIG3_reg <= '0';
        csr_TRIG4_reg <= '0';
        csr_TRIG5_reg <= '0';
        csr_TRIG6_reg <= '0';
        csr_TRIG7_reg <= '0';
        csr_FORCE0_reg <= '0';
        csr_FORCE1_reg <= '0';
        csr_FORCE2_reg <= '0';
        csr_FORCE3_reg <= '0';
        csr_FORCE4_reg <= '0';
        csr_FORCE5_reg <= '0';
        csr_PLL_RST_reg <= '0';
        csr_SERDES_RST_reg <= '0';
        csr_wack <= '0';
      else
        if csr_wreq = '1' then
          csr_TRIG0_reg <= wr_dat_d0(0);
          csr_TRIG1_reg <= wr_dat_d0(1);
          csr_TRIG2_reg <= wr_dat_d0(2);
          csr_TRIG3_reg <= wr_dat_d0(3);
          csr_TRIG4_reg <= wr_dat_d0(4);
          csr_TRIG5_reg <= wr_dat_d0(5);
          csr_TRIG6_reg <= wr_dat_d0(6);
          csr_TRIG7_reg <= wr_dat_d0(7);
          csr_FORCE0_reg <= wr_dat_d0(8);
          csr_FORCE1_reg <= wr_dat_d0(9);
          csr_FORCE2_reg <= wr_dat_d0(10);
          csr_FORCE3_reg <= wr_dat_d0(11);
          csr_FORCE4_reg <= wr_dat_d0(12);
          csr_FORCE5_reg <= wr_dat_d0(13);
          csr_PLL_RST_reg <= wr_dat_d0(20);
          csr_SERDES_RST_reg <= wr_dat_d0(21);
        else
          csr_TRIG0_reg <= '0';
          csr_TRIG1_reg <= '0';
          csr_TRIG2_reg <= '0';
          csr_TRIG3_reg <= '0';
          csr_TRIG4_reg <= '0';
          csr_TRIG5_reg <= '0';
          csr_TRIG6_reg <= '0';
          csr_TRIG7_reg <= '0';
          csr_FORCE0_reg <= '0';
          csr_FORCE1_reg <= '0';
          csr_FORCE2_reg <= '0';
          csr_FORCE3_reg <= '0';
          csr_FORCE4_reg <= '0';
          csr_FORCE5_reg <= '0';
        end if;
        csr_wack <= csr_wreq;
      end if;
    end if;
  end process;

  -- Register OCR0A
  fpgen_regs_o.OCR0A_FINE <= OCR0A_FINE_reg;
  fpgen_regs_o.OCR0A_POL <= OCR0A_POL_reg;
  fpgen_regs_o.OCR0A_COARSE <= OCR0A_COARSE_reg;
  fpgen_regs_o.OCR0A_CONT <= OCR0A_CONT_reg;
  fpgen_regs_o.OCR0A_TRIG_SEL <= OCR0A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR0A_FINE_reg <= "000000000000";
        OCR0A_POL_reg <= '0';
        OCR0A_COARSE_reg <= "00000";
        OCR0A_CONT_reg <= '0';
        OCR0A_TRIG_SEL_reg <= '0';
        OCR0A_wack <= '0';
      else
        if OCR0A_wreq = '1' then
          OCR0A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR0A_POL_reg <= wr_dat_d0(12);
          OCR0A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR0A_CONT_reg <= wr_dat_d0(18);
          OCR0A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR0A_wack <= OCR0A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR0B
  fpgen_regs_o.OCR0B_PPS_OFFS <= OCR0B_PPS_OFFS_reg;
  fpgen_regs_o.OCR0B_LENGTH <= OCR0B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR0B_PPS_OFFS_reg <= "0000000000000000";
        OCR0B_LENGTH_reg <= "0000000000000000";
        OCR0B_wack <= '0';
      else
        if OCR0B_wreq = '1' then
          OCR0B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR0B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR0B_wack <= OCR0B_wreq;
      end if;
    end if;
  end process;

  -- Register OCR1A
  fpgen_regs_o.OCR1A_FINE <= OCR1A_FINE_reg;
  fpgen_regs_o.OCR1A_POL <= OCR1A_POL_reg;
  fpgen_regs_o.OCR1A_COARSE <= OCR1A_COARSE_reg;
  fpgen_regs_o.OCR1A_CONT <= OCR1A_CONT_reg;
  fpgen_regs_o.OCR1A_TRIG_SEL <= OCR1A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR1A_FINE_reg <= "000000000000";
        OCR1A_POL_reg <= '0';
        OCR1A_COARSE_reg <= "00000";
        OCR1A_CONT_reg <= '0';
        OCR1A_TRIG_SEL_reg <= '0';
        OCR1A_wack <= '0';
      else
        if OCR1A_wreq = '1' then
          OCR1A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR1A_POL_reg <= wr_dat_d0(12);
          OCR1A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR1A_CONT_reg <= wr_dat_d0(18);
          OCR1A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR1A_wack <= OCR1A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR1B
  fpgen_regs_o.OCR1B_PPS_OFFS <= OCR1B_PPS_OFFS_reg;
  fpgen_regs_o.OCR1B_LENGTH <= OCR1B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR1B_PPS_OFFS_reg <= "0000000000000000";
        OCR1B_LENGTH_reg <= "0000000000000000";
        OCR1B_wack <= '0';
      else
        if OCR1B_wreq = '1' then
          OCR1B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR1B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR1B_wack <= OCR1B_wreq;
      end if;
    end if;
  end process;

  -- Register OCR2A
  fpgen_regs_o.OCR2A_FINE <= OCR2A_FINE_reg;
  fpgen_regs_o.OCR2A_POL <= OCR2A_POL_reg;
  fpgen_regs_o.OCR2A_COARSE <= OCR2A_COARSE_reg;
  fpgen_regs_o.OCR2A_CONT <= OCR2A_CONT_reg;
  fpgen_regs_o.OCR2A_TRIG_SEL <= OCR2A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR2A_FINE_reg <= "000000000000";
        OCR2A_POL_reg <= '0';
        OCR2A_COARSE_reg <= "00000";
        OCR2A_CONT_reg <= '0';
        OCR2A_TRIG_SEL_reg <= '0';
        OCR2A_wack <= '0';
      else
        if OCR2A_wreq = '1' then
          OCR2A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR2A_POL_reg <= wr_dat_d0(12);
          OCR2A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR2A_CONT_reg <= wr_dat_d0(18);
          OCR2A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR2A_wack <= OCR2A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR2B
  fpgen_regs_o.OCR2B_PPS_OFFS <= OCR2B_PPS_OFFS_reg;
  fpgen_regs_o.OCR2B_LENGTH <= OCR2B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR2B_PPS_OFFS_reg <= "0000000000000000";
        OCR2B_LENGTH_reg <= "0000000000000000";
        OCR2B_wack <= '0';
      else
        if OCR2B_wreq = '1' then
          OCR2B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR2B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR2B_wack <= OCR2B_wreq;
      end if;
    end if;
  end process;

  -- Register OCR3A
  fpgen_regs_o.OCR3A_FINE <= OCR3A_FINE_reg;
  fpgen_regs_o.OCR3A_POL <= OCR3A_POL_reg;
  fpgen_regs_o.OCR3A_COARSE <= OCR3A_COARSE_reg;
  fpgen_regs_o.OCR3A_CONT <= OCR3A_CONT_reg;
  fpgen_regs_o.OCR3A_TRIG_SEL <= OCR3A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR3A_FINE_reg <= "000000000000";
        OCR3A_POL_reg <= '0';
        OCR3A_COARSE_reg <= "00000";
        OCR3A_CONT_reg <= '0';
        OCR3A_TRIG_SEL_reg <= '0';
        OCR3A_wack <= '0';
      else
        if OCR3A_wreq = '1' then
          OCR3A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR3A_POL_reg <= wr_dat_d0(12);
          OCR3A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR3A_CONT_reg <= wr_dat_d0(18);
          OCR3A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR3A_wack <= OCR3A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR3B
  fpgen_regs_o.OCR3B_PPS_OFFS <= OCR3B_PPS_OFFS_reg;
  fpgen_regs_o.OCR3B_LENGTH <= OCR3B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR3B_PPS_OFFS_reg <= "0000000000000000";
        OCR3B_LENGTH_reg <= "0000000000000000";
        OCR3B_wack <= '0';
      else
        if OCR3B_wreq = '1' then
          OCR3B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR3B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR3B_wack <= OCR3B_wreq;
      end if;
    end if;
  end process;

  -- Register OCR4A
  fpgen_regs_o.OCR4A_FINE <= OCR4A_FINE_reg;
  fpgen_regs_o.OCR4A_POL <= OCR4A_POL_reg;
  fpgen_regs_o.OCR4A_COARSE <= OCR4A_COARSE_reg;
  fpgen_regs_o.OCR4A_CONT <= OCR4A_CONT_reg;
  fpgen_regs_o.OCR4A_TRIG_SEL <= OCR4A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR4A_FINE_reg <= "000000000000";
        OCR4A_POL_reg <= '0';
        OCR4A_COARSE_reg <= "00000";
        OCR4A_CONT_reg <= '0';
        OCR4A_TRIG_SEL_reg <= '0';
        OCR4A_wack <= '0';
      else
        if OCR4A_wreq = '1' then
          OCR4A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR4A_POL_reg <= wr_dat_d0(12);
          OCR4A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR4A_CONT_reg <= wr_dat_d0(18);
          OCR4A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR4A_wack <= OCR4A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR4B
  fpgen_regs_o.OCR4B_PPS_OFFS <= OCR4B_PPS_OFFS_reg;
  fpgen_regs_o.OCR4B_LENGTH <= OCR4B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR4B_PPS_OFFS_reg <= "0000000000000000";
        OCR4B_LENGTH_reg <= "0000000000000000";
        OCR4B_wack <= '0';
      else
        if OCR4B_wreq = '1' then
          OCR4B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR4B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR4B_wack <= OCR4B_wreq;
      end if;
    end if;
  end process;

  -- Register OCR5A
  fpgen_regs_o.OCR5A_FINE <= OCR5A_FINE_reg;
  fpgen_regs_o.OCR5A_POL <= OCR5A_POL_reg;
  fpgen_regs_o.OCR5A_COARSE <= OCR5A_COARSE_reg;
  fpgen_regs_o.OCR5A_CONT <= OCR5A_CONT_reg;
  fpgen_regs_o.OCR5A_TRIG_SEL <= OCR5A_TRIG_SEL_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR5A_FINE_reg <= "000000000000";
        OCR5A_POL_reg <= '0';
        OCR5A_COARSE_reg <= "00000";
        OCR5A_CONT_reg <= '0';
        OCR5A_TRIG_SEL_reg <= '0';
        OCR5A_wack <= '0';
      else
        if OCR5A_wreq = '1' then
          OCR5A_FINE_reg <= wr_dat_d0(11 downto 0);
          OCR5A_POL_reg <= wr_dat_d0(12);
          OCR5A_COARSE_reg <= wr_dat_d0(17 downto 13);
          OCR5A_CONT_reg <= wr_dat_d0(18);
          OCR5A_TRIG_SEL_reg <= wr_dat_d0(19);
        end if;
        OCR5A_wack <= OCR5A_wreq;
      end if;
    end if;
  end process;

  -- Register OCR5B
  fpgen_regs_o.OCR5B_PPS_OFFS <= OCR5B_PPS_OFFS_reg;
  fpgen_regs_o.OCR5B_LENGTH <= OCR5B_LENGTH_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OCR5B_PPS_OFFS_reg <= "0000000000000000";
        OCR5B_LENGTH_reg <= "0000000000000000";
        OCR5B_wack <= '0';
      else
        if OCR5B_wreq = '1' then
          OCR5B_PPS_OFFS_reg <= wr_dat_d0(15 downto 0);
          OCR5B_LENGTH_reg <= wr_dat_d0(31 downto 16);
        end if;
        OCR5B_wack <= OCR5B_wreq;
      end if;
    end if;
  end process;

  -- Register odelay_calib
  fpgen_regs_o.odelay_calib_rst_idelayctrl <= odelay_calib_rst_idelayctrl_reg;
  fpgen_regs_o.odelay_calib_rst_odelay <= odelay_calib_rst_odelay_reg;
  fpgen_regs_o.odelay_calib_rst_oserdes <= odelay_calib_rst_oserdes_reg;
  fpgen_regs_o.odelay_calib_rdy <= wr_dat_d0(3);
  fpgen_regs_o.odelay_calib_value <= wr_dat_d0(12 downto 4);
  fpgen_regs_o.odelay_calib_value_update <= odelay_calib_value_update_reg;
  fpgen_regs_o.odelay_calib_en_vtc <= odelay_calib_en_vtc_reg;
  fpgen_regs_o.odelay_calib_cal_latch <= odelay_calib_cal_latch_reg;
  fpgen_regs_o.odelay_calib_taps <= wr_dat_d0(24 downto 16);
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        odelay_calib_rst_idelayctrl_reg <= '0';
        odelay_calib_rst_odelay_reg <= '0';
        odelay_calib_rst_oserdes_reg <= '0';
        odelay_calib_value_update_reg <= '0';
        odelay_calib_en_vtc_reg <= '0';
        odelay_calib_cal_latch_reg <= '0';
        odelay_calib_wack <= '0';
      else
        if odelay_calib_wreq = '1' then
          odelay_calib_rst_idelayctrl_reg <= wr_dat_d0(0);
          odelay_calib_rst_odelay_reg <= wr_dat_d0(1);
          odelay_calib_rst_oserdes_reg <= wr_dat_d0(2);
          odelay_calib_value_update_reg <= wr_dat_d0(13);
          odelay_calib_en_vtc_reg <= wr_dat_d0(14);
          odelay_calib_cal_latch_reg <= wr_dat_d0(15);
        else
          odelay_calib_value_update_reg <= '0';
          odelay_calib_cal_latch_reg <= '0';
        end if;
        odelay_calib_wack <= odelay_calib_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, csr_wack, OCR0A_wack, OCR0B_wack, OCR1A_wack,
           OCR1B_wack, OCR2A_wack, OCR2B_wack, OCR3A_wack, OCR3B_wack, OCR4A_wack,
           OCR4B_wack, OCR5A_wack, OCR5B_wack, odelay_calib_wack) begin
    csr_wreq <= '0';
    OCR0A_wreq <= '0';
    OCR0B_wreq <= '0';
    OCR1A_wreq <= '0';
    OCR1B_wreq <= '0';
    OCR2A_wreq <= '0';
    OCR2B_wreq <= '0';
    OCR3A_wreq <= '0';
    OCR3B_wreq <= '0';
    OCR4A_wreq <= '0';
    OCR4B_wreq <= '0';
    OCR5A_wreq <= '0';
    OCR5B_wreq <= '0';
    odelay_calib_wreq <= '0';
    case wr_adr_d0(5 downto 2) is
    when "0000" =>
      -- Reg csr
      csr_wreq <= wr_req_d0;
      wr_ack_int <= csr_wack;
    when "0001" =>
      -- Reg OCR0A
      OCR0A_wreq <= wr_req_d0;
      wr_ack_int <= OCR0A_wack;
    when "0010" =>
      -- Reg OCR0B
      OCR0B_wreq <= wr_req_d0;
      wr_ack_int <= OCR0B_wack;
    when "0011" =>
      -- Reg OCR1A
      OCR1A_wreq <= wr_req_d0;
      wr_ack_int <= OCR1A_wack;
    when "0100" =>
      -- Reg OCR1B
      OCR1B_wreq <= wr_req_d0;
      wr_ack_int <= OCR1B_wack;
    when "0101" =>
      -- Reg OCR2A
      OCR2A_wreq <= wr_req_d0;
      wr_ack_int <= OCR2A_wack;
    when "0110" =>
      -- Reg OCR2B
      OCR2B_wreq <= wr_req_d0;
      wr_ack_int <= OCR2B_wack;
    when "0111" =>
      -- Reg OCR3A
      OCR3A_wreq <= wr_req_d0;
      wr_ack_int <= OCR3A_wack;
    when "1000" =>
      -- Reg OCR3B
      OCR3B_wreq <= wr_req_d0;
      wr_ack_int <= OCR3B_wack;
    when "1001" =>
      -- Reg OCR4A
      OCR4A_wreq <= wr_req_d0;
      wr_ack_int <= OCR4A_wack;
    when "1010" =>
      -- Reg OCR4B
      OCR4B_wreq <= wr_req_d0;
      wr_ack_int <= OCR4B_wack;
    when "1011" =>
      -- Reg OCR5A
      OCR5A_wreq <= wr_req_d0;
      wr_ack_int <= OCR5A_wack;
    when "1100" =>
      -- Reg OCR5B
      OCR5B_wreq <= wr_req_d0;
      wr_ack_int <= OCR5B_wack;
    when "1101" =>
      -- Reg odelay_calib
      odelay_calib_wreq <= wr_req_d0;
      wr_ack_int <= odelay_calib_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, fpgen_regs_i.csr_READY, csr_PLL_RST_reg,
           csr_SERDES_RST_reg, fpgen_regs_i.csr_PLL_LOCKED, OCR0A_FINE_reg,
           OCR0A_POL_reg, OCR0A_COARSE_reg, OCR0A_CONT_reg, OCR0A_TRIG_SEL_reg,
           OCR0B_PPS_OFFS_reg, OCR0B_LENGTH_reg, OCR1A_FINE_reg, OCR1A_POL_reg,
           OCR1A_COARSE_reg, OCR1A_CONT_reg, OCR1A_TRIG_SEL_reg,
           OCR1B_PPS_OFFS_reg, OCR1B_LENGTH_reg, OCR2A_FINE_reg, OCR2A_POL_reg,
           OCR2A_COARSE_reg, OCR2A_CONT_reg, OCR2A_TRIG_SEL_reg,
           OCR2B_PPS_OFFS_reg, OCR2B_LENGTH_reg, OCR3A_FINE_reg, OCR3A_POL_reg,
           OCR3A_COARSE_reg, OCR3A_CONT_reg, OCR3A_TRIG_SEL_reg,
           OCR3B_PPS_OFFS_reg, OCR3B_LENGTH_reg, OCR4A_FINE_reg, OCR4A_POL_reg,
           OCR4A_COARSE_reg, OCR4A_CONT_reg, OCR4A_TRIG_SEL_reg,
           OCR4B_PPS_OFFS_reg, OCR4B_LENGTH_reg, OCR5A_FINE_reg, OCR5A_POL_reg,
           OCR5A_COARSE_reg, OCR5A_CONT_reg, OCR5A_TRIG_SEL_reg,
           OCR5B_PPS_OFFS_reg, OCR5B_LENGTH_reg,
           odelay_calib_rst_idelayctrl_reg, odelay_calib_rst_odelay_reg,
           odelay_calib_rst_oserdes_reg, fpgen_regs_i.odelay_calib_rdy,
           fpgen_regs_i.odelay_calib_value, odelay_calib_en_vtc_reg,
           fpgen_regs_i.odelay_calib_taps) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case adr_int(5 downto 2) is
    when "0000" =>
      -- Reg csr
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= '0';
      rd_dat_d0(1) <= '0';
      rd_dat_d0(2) <= '0';
      rd_dat_d0(3) <= '0';
      rd_dat_d0(4) <= '0';
      rd_dat_d0(5) <= '0';
      rd_dat_d0(6) <= '0';
      rd_dat_d0(7) <= '0';
      rd_dat_d0(8) <= '0';
      rd_dat_d0(9) <= '0';
      rd_dat_d0(10) <= '0';
      rd_dat_d0(11) <= '0';
      rd_dat_d0(12) <= '0';
      rd_dat_d0(13) <= '0';
      rd_dat_d0(19 downto 14) <= fpgen_regs_i.csr_READY;
      rd_dat_d0(20) <= csr_PLL_RST_reg;
      rd_dat_d0(21) <= csr_SERDES_RST_reg;
      rd_dat_d0(22) <= fpgen_regs_i.csr_PLL_LOCKED;
      rd_dat_d0(31 downto 23) <= (others => '0');
    when "0001" =>
      -- Reg OCR0A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR0A_FINE_reg;
      rd_dat_d0(12) <= OCR0A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR0A_COARSE_reg;
      rd_dat_d0(18) <= OCR0A_CONT_reg;
      rd_dat_d0(19) <= OCR0A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "0010" =>
      -- Reg OCR0B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR0B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR0B_LENGTH_reg;
    when "0011" =>
      -- Reg OCR1A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR1A_FINE_reg;
      rd_dat_d0(12) <= OCR1A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR1A_COARSE_reg;
      rd_dat_d0(18) <= OCR1A_CONT_reg;
      rd_dat_d0(19) <= OCR1A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "0100" =>
      -- Reg OCR1B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR1B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR1B_LENGTH_reg;
    when "0101" =>
      -- Reg OCR2A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR2A_FINE_reg;
      rd_dat_d0(12) <= OCR2A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR2A_COARSE_reg;
      rd_dat_d0(18) <= OCR2A_CONT_reg;
      rd_dat_d0(19) <= OCR2A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "0110" =>
      -- Reg OCR2B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR2B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR2B_LENGTH_reg;
    when "0111" =>
      -- Reg OCR3A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR3A_FINE_reg;
      rd_dat_d0(12) <= OCR3A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR3A_COARSE_reg;
      rd_dat_d0(18) <= OCR3A_CONT_reg;
      rd_dat_d0(19) <= OCR3A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "1000" =>
      -- Reg OCR3B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR3B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR3B_LENGTH_reg;
    when "1001" =>
      -- Reg OCR4A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR4A_FINE_reg;
      rd_dat_d0(12) <= OCR4A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR4A_COARSE_reg;
      rd_dat_d0(18) <= OCR4A_CONT_reg;
      rd_dat_d0(19) <= OCR4A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "1010" =>
      -- Reg OCR4B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR4B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR4B_LENGTH_reg;
    when "1011" =>
      -- Reg OCR5A
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(11 downto 0) <= OCR5A_FINE_reg;
      rd_dat_d0(12) <= OCR5A_POL_reg;
      rd_dat_d0(17 downto 13) <= OCR5A_COARSE_reg;
      rd_dat_d0(18) <= OCR5A_CONT_reg;
      rd_dat_d0(19) <= OCR5A_TRIG_SEL_reg;
      rd_dat_d0(31 downto 20) <= (others => '0');
    when "1100" =>
      -- Reg OCR5B
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= OCR5B_PPS_OFFS_reg;
      rd_dat_d0(31 downto 16) <= OCR5B_LENGTH_reg;
    when "1101" =>
      -- Reg odelay_calib
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= odelay_calib_rst_idelayctrl_reg;
      rd_dat_d0(1) <= odelay_calib_rst_odelay_reg;
      rd_dat_d0(2) <= odelay_calib_rst_oserdes_reg;
      rd_dat_d0(3) <= fpgen_regs_i.odelay_calib_rdy;
      rd_dat_d0(12 downto 4) <= fpgen_regs_i.odelay_calib_value;
      rd_dat_d0(13) <= '0';
      rd_dat_d0(14) <= odelay_calib_en_vtc_reg;
      rd_dat_d0(15) <= '0';
      rd_dat_d0(24 downto 16) <= fpgen_regs_i.odelay_calib_taps;
      rd_dat_d0(31 downto 25) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
