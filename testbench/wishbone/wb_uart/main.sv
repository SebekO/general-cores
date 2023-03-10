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

`timescale 1ps / 1ps

`include "vhd_wishbone_master.svh"
`include "wb_uart_regs.vh"

import wishbone_pkg::*;
import gencores_sim_pkg::*;

class WBUartDriver extends CBusDevice;
   protected bit m_with_fifo;
   protected bit m_with_vuart;
   protected mailbox #(uint8_t) m_tx_queue;
   protected mailbox #(uint8_t) m_rx_queue;
   protected mailbox #(uint8_t) m_vuart_tx_queue;
   protected mailbox #(uint8_t) m_vuart_rx_queue;
   protected bit m_tx_idle;
   protected int m_prev_r;

   function new(CBusAccessor bus, uint64_t base, bit with_vuart = 0);
      super.new(bus, base);
      m_with_vuart = with_vuart;

   endfunction  // new

   function automatic uint32_t calc_baudrate(uint64_t baudrate, uint64_t base_clock);
      return ((((baudrate << 12)) + (base_clock >> 8)) / (base_clock >> 7));
   endfunction

   task automatic init(uint32_t baudrate, uint32_t clock_freq, int fifo_en);
      uint32_t rv;
      Logger   logger = Logger::get();

      m_tx_queue = new;
      m_rx_queue = new;
      m_vuart_tx_queue = new;
      m_vuart_rx_queue = new;

      readl(`ADDR_UART_SR, rv);
      logger.msg(1, $sformatf("uart_init SR=%b", rv));

      writel(`ADDR_UART_BCR, calc_baudrate(baudrate, clock_freq));
      if (!fifo_en) m_with_fifo = 0;
      else m_with_fifo = (rv & `UART_SR_RX_FIFO_SUPPORTED) ? 1 : 0;

      m_tx_idle = 0;

      logger.msg(1, $sformatf("wb_simple_uart: FIFO supported = %d", m_with_fifo));
   endtask  // init

   task automatic send(byte value);
      m_tx_queue.put(value);
      m_tx_idle = 0;
      //    update();
   endtask  // send

   task automatic send_vuart(byte value);
      m_vuart_tx_queue.put(value);
   endtask

   task automatic recv_with_timeout(inout int rv, input time timeout, input int poll = 1);
      recv_with_timeout_common(rv, timeout, poll, 0);
   endtask

   task automatic recv_with_timeout_vuart(inout int rv, input time timeout, input int poll = 1);
      recv_with_timeout_common(rv, timeout, poll, 1);
   endtask


   task automatic recv_with_timeout_common(inout int rv, input time timeout, input int poll = 1,
                                           input int is_vuart);
      automatic time t_start = $time;


      while ($time - t_start < timeout) begin
         automatic int r;
         if (poll) update();

         if (is_vuart) recv_vuart(r);
         else recv(r);

         if (r >= 0) begin

            rv = r;
            m_prev_r = r;
            return;
         end
         #1us;
      end
      rv = -1;
   endtask

   task automatic recv(output int value);
      if (rx_count() == 0) begin
         value = -1;
         return;
      end

      m_rx_queue.get(value);
   endtask  // recv

   task automatic recv_vuart(output int value);
      if (rx_count_vuart() == 0) begin
         value = -1;
         return;
      end

      m_vuart_rx_queue.get(value);
   endtask  // recv

   function automatic int rx_count();
      return m_rx_queue.num();
   endfunction  // rx_count

   function automatic int rx_count_vuart();
      return m_vuart_rx_queue.num();
   endfunction  // rx_count

   function automatic bit poll();
      return m_rx_queue.num() > 0;
   endfunction  // has_data

   function automatic bit poll_vuart();
      return m_vuart_rx_queue.num() > 0;
   endfunction  // has_data

   function automatic bit tx_idle();

      return m_tx_idle;
   endfunction  // tx_idle

   function automatic bit rx_overflow();
   endfunction  // rx_overflow

   task automatic update();
      automatic uint32_t sr, host_rdr, host_tdr;
      automatic time ts = $time;


      if (m_with_vuart) begin
         readl(`ADDR_UART_HOST_RDR, host_rdr);

         if (host_rdr & `UART_HOST_RDR_RDY) begin
            m_vuart_rx_queue.put(host_rdr & `UART_HOST_RDR_DATA);
         end


         if (m_vuart_tx_queue.num()) begin
            forever begin
               readl(`ADDR_UART_HOST_TDR, host_tdr);
               if (host_tdr & `UART_HOST_RDR_RDY) begin
                  automatic int b;
                  m_vuart_tx_queue.get(b);
                  writel(`ADDR_UART_HOST_TDR, b);
                  break;
               end
            end
         end
      end

      readl(`ADDR_UART_SR, sr);

      if (m_with_fifo) begin
         if (sr & `UART_SR_RX_RDY) begin
            automatic uint32_t d;
            readl(`ADDR_UART_RDR, d);
            m_rx_queue.put(d);
            //        $warning("FifoRx: %x qs %d", d, m_rx_queue.num());
         end

         if (!(sr & `UART_SR_TX_FIFO_FULL) && m_tx_queue.num() > 0) begin
            automatic int b;
            m_tx_queue.get(b);
            //      $display("-> FifoTX %x", b);
            writel(`ADDR_UART_TDR, b);
         end else if (!m_tx_queue.num()) begin
            m_tx_idle = 1;
         end


      end else begin
         if (!(sr & `UART_SR_TX_BUSY) && m_tx_queue.num() > 0) begin
            automatic int b;
            m_tx_queue.get(b);
            //        $warning("NoFifoTX %d %x", d, `ADDR_UART_TDR );
            writel(`ADDR_UART_TDR, b);
         end else if (!m_tx_queue.num()) begin
            m_tx_idle = 1;
         end



         if (sr & `UART_SR_RX_RDY) begin
            automatic uint32_t d;
            readl(`ADDR_UART_RDR, d);
            //$display("NoFifoRx: %x [%d ent]", d, m_rx_queue.num());
            m_rx_queue.put(d);
         end
      end
   endtask  // update
endclass  // WBUartDriver


module wb_uart_test_wrapper #(
    parameter bit g_WITH_VIRTUAL_UART,
    parameter bit g_WITH_PHYSICAL_UART,
    parameter bit g_WITH_PHYSICAL_UART_FIFO
) (
    input clk_sys_i,
    input rst_n_i
);

   reg rst_host_n = 0;

   initial begin
      repeat (10) @(posedge clk_sys_i);
      rst_host_n <= 1;
      @(posedge clk_sys_i);
   end

   IVHDWishboneMaster Host1 (
       .clk_i  (clk_sys_i),
       .rst_n_i(rst_host_n)
   );

   function automatic CWishboneAccessor get_accessor();
      return Host1.get_accessor();
   endfunction

   wire loop;

   // the Device Under Test
   xwb_simple_uart #(
       .g_WITH_PHYSICAL_UART(g_WITH_PHYSICAL_UART),
       .g_WITH_VIRTUAL_UART(g_WITH_VIRTUAL_UART),
       .g_WITH_PHYSICAL_UART_FIFO(g_WITH_PHYSICAL_UART_FIFO),
       .g_TX_FIFO_SIZE(64),
       .g_RX_FIFO_SIZE(64),
       .g_INTERFACE_MODE(PIPELINED),
       .g_ADDRESS_GRANULARITY(0)
   ) DUT_FIFO (
       .rst_n_i  (rst_n_i),
       .clk_sys_i(clk_sys_i),

       .slave_i(Host1.out),
       .slave_o(Host1.in),

       .uart_txd_o(loop),
       .uart_rxd_i(loop)
   );


endmodule





module main;

   reg rst_n = 0;
   reg clk_62m5 = 0;

   localparam int c_BAUDRATE = 921600;
   localparam int c_SYS_CLOCK_FREQ_HZ = 62500000;

   always #8ns clk_62m5 <= ~clk_62m5;

   initial begin
      repeat (20) @(posedge clk_62m5);
      rst_n = 1;
   end



   wb_uart_test_wrapper #(
       .g_WITH_VIRTUAL_UART(1'b0),
       .g_WITH_PHYSICAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART_FIFO(1'b1)
   ) DUT_PhysFIFO (
       .rst_n_i  (rst_n),
       .clk_sys_i(clk_62m5)
   );

   wb_uart_test_wrapper #(
       .g_WITH_VIRTUAL_UART(1'b0),
       .g_WITH_PHYSICAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART_FIFO(1'b0)
   ) DUT_PhysNoFIFO (
       .rst_n_i  (rst_n),
       .clk_sys_i(clk_62m5)
   );



   wb_uart_test_wrapper #(
       .g_WITH_VIRTUAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART_FIFO(1'b1)
   ) DUT_PhysVUartFIFO (
       .rst_n_i  (rst_n),
       .clk_sys_i(clk_62m5)
   );

   wb_uart_test_wrapper #(
       .g_WITH_VIRTUAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART(1'b1),
       .g_WITH_PHYSICAL_UART_FIFO(1'b0)
   ) DUT_PhysVUartNoFIFO (
       .rst_n_i  (rst_n),
       .clk_sys_i(clk_62m5)
   );


   class UARTTestFixture;

      protected CWishboneAccessor accs[4];
      protected WBUartDriver drv_fifo, drv_no_fifo, drv_vuart_fifo, drv_vuart_no_fifo;

      task automatic init();
         rst_n <= 0;
         repeat (10) @(posedge clk_62m5);
         rst_n <= 1;
         repeat (10) @(posedge clk_62m5);

         accs[0] = DUT_PhysFIFO.get_accessor();
         accs[1] = DUT_PhysNoFIFO.get_accessor();
         accs[2] = DUT_PhysVUartFIFO.get_accessor();
         accs[3] = DUT_PhysVUartNoFIFO.get_accessor();

         accs[0].set_mode(PIPELINED);
         accs[1].set_mode(PIPELINED);
         accs[2].set_mode(PIPELINED);
         accs[3].set_mode(PIPELINED);

         drv_fifo = new(accs[0], 0);
         drv_no_fifo = new(accs[1], 0);
         drv_vuart_fifo = new(accs[2], 0, 1);
         drv_vuart_no_fifo = new(accs[3], 0, 1);
         drv_fifo.init(c_BAUDRATE, c_SYS_CLOCK_FREQ_HZ, 1);
         drv_no_fifo.init(c_BAUDRATE, c_SYS_CLOCK_FREQ_HZ, 0);
         drv_vuart_fifo.init(c_BAUDRATE, c_SYS_CLOCK_FREQ_HZ, 1);
         drv_vuart_no_fifo.init(c_BAUDRATE, c_SYS_CLOCK_FREQ_HZ, 0);
      endtask


      task automatic run_rx_tx_test(int with_vuart, int with_fifo, int tx_to_vuart,
                                    int rx_from_vuart);
         Logger logger = Logger::get();
         const int c_N_TX_BYTES = 2048;
         const time c_BYTE_TIMEOUT = 500us;
         u8_vector_t txBytes, rxBytes;
         bit fail = 0;
         int i;
         int active = 1;

         automatic WBUartDriver drv;

         logger.startTest($sformatf(
                          "TX[%s]/RX[%s] %sFIFO %sVUART",
                          tx_to_vuart ? "VUART" : "PHYS",
                          rx_from_vuart ? "VUART" : "PHYS",
                          with_fifo ? "+" : "-",
                          with_vuart ? "+" : "-"
                          ));

         init();

         if (with_vuart) drv = with_fifo ? drv_vuart_fifo : drv_vuart_no_fifo;
         else drv = with_fifo ? drv_fifo : drv_no_fifo;


         fork
            begin : upd_proc
               while (active) begin
                  drv.update();
                  #100ns;
               end
            end
            begin : tx_proc
               automatic int i;
               for (i = 0; i < c_N_TX_BYTES; i++) begin
                  txBytes.push_back(i);
                  if (tx_to_vuart) drv.send_vuart(i);
                  else drv.send(i);
               end
               logger.msg(1, "TX complete");
            end

            begin : rx_proc
               automatic int i;
               forever begin
                  automatic int r;
                  if (rx_from_vuart)
                     drv.recv_with_timeout_vuart(r, c_BYTE_TIMEOUT,
                                                 0);  // we are polled 10 lines up from here ^^^^
                  else
                     drv.recv_with_timeout(r, c_BYTE_TIMEOUT,
                                           0);  // we are polled 10 lines up from here ^^^^
                  if (r >= 0) begin

                     rxBytes.push_back(r);
                     //$warning("RRRRX %x %d %d", r, rxBytes.size(), c_N_TX_BYTES );
                     if (rxBytes.size() >= c_N_TX_BYTES) break;
                  end else begin
                     logger.fail("RX timeout expired");
                     fail = 1;
                     break;
                  end
                  #1us;
               end

               #100us;
               if (rx_from_vuart && drv.rx_count_vuart() > 0) begin
                  automatic int cnt = drv.rx_count_vuart(), b;
                  for (i = 0; i < cnt; i++) begin
                     drv.recv_vuart(b);
                     rxBytes.push_back(b);
                  end

               end else if (!rx_from_vuart && drv.rx_count() > 0) begin
                  automatic int cnt = drv.rx_count(), b;
                  for (i = 0; i < cnt; i++) begin
                     drv.recv(b);
                     rxBytes.push_back(b);
                  end
               end

               logger.msg(1, "RX complete");
               active = 0;
            end
         join

         if (fail) return;

         logger.msg(1, $sformatf("TX bytes: %d, RX bytes: %d", txBytes.size(), rxBytes.size()));

         if (txBytes.size() != rxBytes.size()) begin
            logger.fail("TX bytes != RX bytes count");
            for (i = 0; i < txBytes.size(); i++)
               logger.fail($sformatf("TX[%d] = %02x", i, txBytes[i]));
            for (i = 0; i < rxBytes.size(); i++)
               logger.fail($sformatf("RX[%d] = %02x", i, rxBytes[i]));

            return;
         end

         for (i = 0; i < txBytes.size(); i++) begin
            if (txBytes[i] != rxBytes[i]) begin
               logger.fail($sformatf(
                           "Byte %d didn't match: TX = %02x RX = %02x", i, txBytes[i], rxBytes[i]));
               return;
            end
         end

         logger.pass();

      endtask


   endclass




   initial begin
      automatic Logger logger = Logger::get();
      automatic UARTTestFixture t;

      #1us;

      t = new;
      // TX using Vuart
      t.run_rx_tx_test(1, 1, 1, 0);
      t.run_rx_tx_test(1, 0, 1, 0);
      // RX using Vuart
      t.run_rx_tx_test(1, 1, 0, 1);
      t.run_rx_tx_test(1, 0, 0, 1);

      // TX/RX physical, with and without VUart/FIFO variants
      t.run_rx_tx_test(0, 0, 0, 0);
      t.run_rx_tx_test(1, 0, 0, 0);
      t.run_rx_tx_test(1, 1, 0, 0);
      t.run_rx_tx_test(0, 1, 0, 0);

      $stop;


   end  // initial begin

endmodule  // main
