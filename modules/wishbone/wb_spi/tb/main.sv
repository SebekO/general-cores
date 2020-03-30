//------------------------------------------------------------------------------
// CERN BE-CO-HT
// General Cores Library
// https://www.ohwr.org/project/general-cores
//------------------------------------------------------------------------------
//
// unit name:   main
//
// description: Testbench for the WB SPI master module
//
//------------------------------------------------------------------------------
// Copyright CERN 2019
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

`timescale 1ns/1ns

`include "spi_sim.svh"
`include "vhd_wishbone_master.svh"

import wishbone_pkg::*;

module main;

   wire spi_irq;

   reg clk_sys = 0;

   reg rst_n;

   always #5ns clk_sys <= ~clk_sys;

   initial begin
      rst_n <= 0;
      repeat(10) @(posedge clk_sys);
      rst_n <= 1;
   end

   IVHDWishboneMaster host(clk_sys, rst_n);

   IFACE_SPI ispi();

   xwb_spi #
     (
      .g_interface_mode      (0), // Classic
      .g_address_granularity (0), // Byte
      .g_divider_len         (16),
      .g_max_char_len        (8),
      .g_num_slaves          (1)
      )
   DUT
     (
      .clk_sys_i  (clk_sys),
      .rst_n_i    (rst_n),
      .slave_i    (host.out),
      .slave_o    (host.in),
      .desc_o     (),
      .int_o      (spi_irq),
      .pad_cs_o   (ispi.cs_n),
      .pad_sclk_o (ispi.sclk),
      .pad_mosi_o (ispi.mosi),
      .pad_miso_i (ispi.miso_out)
      );

   CSPI_Slave spi;

   CBusAccessor wb;

   viSpiSlave spi_iface = ispi.slave;

   initial begin

      uint64_t val;

      $timeformat (-6, 3, "us", 10);

      wb = host.get_accessor();
      wb.set_default_xfer_size(4);

      spi = new(spi_iface, 8);
      spi.run();

      fork
         begin
            #10us;

            for (int i = 0; i < 4; i++) begin
               automatic bit cpol = i / 2;
               automatic bit cpha = i % 2;

               spi.set_mode(~cpol, cpha);

               val  = 'h1008;
               val |= cpol << 10;
               val |= cpha << 9;
               $display("%.4x, %0d, %0d",val, ~cpol, cpha);
               
               wb.write('h10, val);
               wb.write('h14, 'h4);
               wb.write('h00, 'h85);
               wb.write('h18, 'h1);
               wb.write('h10, val | 'h100);
               #1us;
               wb.read('h10, val);

               #10us;

               wb.write('h00, 'h85);
               wb.write('h10, val | 'h100);
               #1us;
               wb.read('h10, val);

               #10us;

            end

            $finish;

         end

         begin
            automatic bit data[] = new[8];
            automatic bit [7:0] data_packed;
            forever @(posedge spi_irq) begin
               spi.get_data(data);
               data_packed = { << {data} };
               $display("0b%b (0x%h)", data_packed, data_packed);
            end
         end
      join
   end
endmodule // main
