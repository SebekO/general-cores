//////////////////////////////////////////////////////////////////////
////                                                              ////
////  spi_top_wrap.sv                                             ////
////                                                              ////
////  This file is part of the SPI IP core project                ////
////  http://www.opencores.org/projects/spi/                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Sebastian Owarzany (sebastian.dawid.owarzany@cern.ch) ////
////                                                              ////
////  All additional information is avaliable in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
//  Modifications:
//      2022-12-20: by Sebastian Owarzany (sebastian.dawid.owarzany@cern.ch)
//          * add mosi_dir_n_o pin from spi_top module
//////////////////////////////////////////////////////////////////////

`default_nettype none

module spi_top_wrap (
  input  wire sdi_i,
  output wire cs_n_o,
  output wire sck_o,
  output wire sdo_o,

  input  wire [4:2]  wb_adr_i,
  input  wire        wb_clk_i,
  input  wire        wb_cyc_i,
  input  wire [31:0] wb_dat_i,
  input  wire        wb_rst_i,
  input  wire [3:0]  wb_sel_i,
  input  wire        wb_stb_i,
  input  wire        wb_we_i,
  output wire        wb_ack_o,
  output wire [31:0] wb_dat_o,
  output wire        wb_err_o
);


  wire [4:0] wb_adr;
  wire [7:0] ss_pad;

  assign wb_adr = {wb_adr_i, 2'b00};

  spi_top #(
    .Tp(1),
    .SPI_DIVIDER_LEN(16),
    .SPI_MAX_CHAR(128),
    .SPI_CHAR_LEN_BITS(7),
    .SPI_SS_NB(8)
  ) spi_top_inst (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_adr_i(wb_adr),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_sel_i(wb_sel_i),
    .wb_we_i(wb_we_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_ack_o(wb_ack_o),
    .wb_err_o(wb_err_o),
    .int_o(),
	  .mosi_dir_n_o(),

    .ss_pad_o(ss_pad),
    .sclk_pad_o(sck_o),
    .mosi_pad_o(sdo_o),
    .miso_pad_i(sdi_i)
  );

  assign cs_n_o = ss_pad[0];

endmodule // spi_top_wrap
