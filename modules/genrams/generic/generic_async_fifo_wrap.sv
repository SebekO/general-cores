///////////////////////////////////////////////////////////////////////////////
// Title      : Parametrizable asynchronous FIFO SystemVerilog wrapper
// Project    : Generics RAMs and FIFOs collection
///////////////////////////////////////////////////////////////////////////////
// File       : generic_async_fifo_wrap.sv
// Author     : Sebastian Owarzany
// Company    : CERN SY/RF/FB
// Created    : 2022/12/02
// Last update: 2022/12/02
// Platform   :
// Standard   : SystemVerilog IEEE 1800
///////////////////////////////////////////////////////////////////////////////
// Description: Dual/clock asynchronous FIFO.
// / configurable data width and size
///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 CERN
///////////////////////////////////////////////////////////////////////////////
// Revisions  :
// Date        Version  Author          Description
// 2022/12/02  1.0      sowarzan        Created
///////////////////////////////////////////////////////////////////////////////

`default_nettype none

module generic_async_fifo_wrap #(
  parameter DATA_WIDTH = 16,
  parameter SIZE       = 2048
) (
  // Control/Data Signals,
  input wire rst_i, // FPGA Reset

  // write port
  input  wire        clk_wr_i,  // Write Clock
  input  wire [15:0] d_i,       // Write data
  input  wire        we_i,      // Write enable
  output wire        wr_full_o, // Write full
  output wire [$clog2(SIZE)-1:0] wr_count_o, // Data counter

  // read port
  input  wire        clk_rd_i,   // Read Clock
  output wire [15:0] q_o,        // Read data
  input  wire        rd_i,       // Read enable
  output wire        rd_empty_o, // Read empty
  output wire [$clog2(SIZE)-1:0] rd_count_o // Data counter
);

  generic_async_fifo #(
    .g_data_width(DATA_WIDTH),
    .g_size(SIZE),
    .g_show_ahead(),

    // Read-side flag selection
    .g_with_rd_empty(),        // with empty flag
    .g_with_rd_full(),         // with full flag
    .g_with_rd_almost_empty(),
    .g_with_rd_almost_full(),
    .g_with_rd_count(),        // with words counter
    .g_with_wr_empty(),
    .g_with_wr_full(),
    .g_with_wr_almost_empty(),
    .g_with_wr_almost_full(),
    .g_with_wr_count(),

    .g_almost_empty_threshold(10),      // threshold for almost empty flag
    .g_almost_full_threshold(SIZE-10)   // threshold for almost full flag

  ) generic_async_fifo_0 (
    .rst_n_i(!rst_i),

    // write port
    .clk_wr_i(clk_wr_i),
    .d_i(d_i),
    .we_i(we_i),

    .wr_empty_o(),
    .wr_full_o(wr_full_o),
    .wr_almost_empty_o(),
    .wr_almost_full_o(),
    .wr_count_o(wr_count_o),

    // read port
    .clk_rd_i(clk_rd_i),
    .q_o(q_o),
    .rd_i(rd_i),

    .rd_empty_o(rd_empty_o),
    .rd_full_o(),
    .rd_almost_empty_o(),
    .rd_almost_full_o(),
    .rd_count_o(rd_count_o)
  );
endmodule // generic_async_fifo_wrap