`include "gencores_sim_defs.svh"

interface ISimpleMemWriteIF (
    input clk_i
);

  parameter g_AW = 32;
  parameter g_DW = 512;

  logic [g_AW-1:0] addr;
  logic [g_DW-1:0] data;
  logic            req;
  logic            ready;
  logic [     7:0] burst_len;
  logic            last;

  modport master(output addr, data, req, burst_len, last, input ready);
  modport slave(input addr, data, req, burst_len, last, output ready);

endinterface  // ISimpleMemWriteIF



package axi_utils;



  import gencores_sim_pkg::*;
  import axi_test::*;


  class CAXI4LiteAccessor extends CBusAccessor;

    parameter g_AW = 32;
    parameter g_DW = 32;

    static int _null = 0;

    typedef virtual AXI_LITE_DV #(
        .AXI_ADDR_WIDTH(g_AW),
        .AXI_DATA_WIDTH(g_DW)
    ) bus_t;

    protected axi_lite_driver #(g_AW, g_DW) m_driver;

    function new(bus_t bus);
      m_driver = new(bus);
    endfunction  // new

    task automatic reset();
      m_driver.reset_master();
    endtask  // reset


    // [master only] generic write(s), blocking
    virtual task automatic writem( input u64_vector_t addr, u64_vector_t data, int size = 4,
                                  ref int result = _null);
      axi_pkg::resp_t resp;

      m_driver.send_aw(addr[0], 0);
      m_driver.send_w(data[0], 'hf);
      m_driver.recv_b(resp);

      //      $display("Write!\n");
    endtask  // write

    // [master only] generic read(s), blocking
    virtual task automatic readm( input u64_vector_t addr, ref u64_vector_t data, input int size = 4,
                                 ref int result = _null);
      logic [31:0] d;
      axi_pkg::resp_t resp;

      m_driver.send_ar(addr[0], 0);
      m_driver.recv_r(d, resp);

      data[0] = d;

    endtask  // readm
  endclass  // CAXI4LiteAccessor

  class CAXI4FullAccessor #(
      parameter g_AW = 32,
      parameter g_DW = 64,
      parameter g_IW = 4,
      parameter g_UW = 2
  ) extends CBusAccessor;

    static int _null = 0;

    typedef virtual AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(g_AW),
        .AXI_DATA_WIDTH(g_DW),
        .AXI_ID_WIDTH  (g_IW),
        .AXI_USER_WIDTH(g_UW)
    ) bus_t;

    typedef axi_ax_beat#(
        .AW(g_AW),
        .IW(g_IW),
        .UW(g_UW)
    ) ax_beat_t;
    typedef axi_w_beat#(
        .DW(g_DW),
        .UW(g_UW)
    ) w_beat_t;
    typedef axi_b_beat#(
        .IW(g_IW),
        .UW(g_UW)
    ) b_beat_t;
    typedef axi_r_beat#(
        .DW(g_DW),
        .IW(g_IW),
        .UW(g_UW)
    ) r_beat_t;

    protected bus_t m_bus;

    protected axi_driver #(g_AW, g_DW, g_IW, g_UW, 0ns, 1ns) m_driver;

    function new(bus_t bus);
      m_bus = bus;
      m_driver = new(bus);
    endfunction  // new

    task automatic reset();
      m_driver.reset_master();
    endtask  // reset


    virtual task write_burst(uint64_t addr, int count, uint64_t data[$], bit insert_gaps = 0,
                             ref int result = _null);
      automatic axi_pkg::resp_t resp;
      automatic ax_beat_t aw_beat = new;
      automatic w_beat_t w_beat = new;
      automatic b_beat_t b_beat = new;

      aw_beat.ax_addr  = addr;
      aw_beat.ax_len   = count - 1;
      aw_beat.ax_burst = axi_pkg::BURST_INCR;


      m_driver.send_aw(aw_beat);

      fork
        begin
          automatic int i;
          for (i = 0; i < count; i++) begin
            w_beat.w_data = data[i];
            w_beat.w_strb = 'hffffffff;
            w_beat.w_last = (i == count - 1) ? 1 : 0;
            m_driver.send_w(w_beat);
            if (insert_gaps) @(posedge m_bus.clk_i);
          end

        end

        m_driver.recv_b(b_beat);
      join
    endtask

    virtual task read_burst(uint64_t addr, int count, ref uint64_t data[$],
                            input bit insert_gaps = 0, ref int result = _null);
      automatic axi_pkg::resp_t resp;
      automatic ax_beat_t ar_beat = new;
      automatic r_beat_t r_beat = new;

      ar_beat.ax_addr  = addr;
      ar_beat.ax_len   = count - 1;
      ar_beat.ax_burst = axi_pkg::BURST_INCR;

      m_driver.send_ar(ar_beat);

      data = '{};
      forever begin
        if (insert_gaps) @(posedge m_bus.clk_i);

        m_driver.recv_r(r_beat);

        // $display("RData %x RLast %d", r_beat.r_data, r_beat.r_last);
        data.push_back(r_beat.r_data);

        if (r_beat.r_last) break;
      end
    endtask

    // [master only] generic write(s), blocking
    virtual task automatic writem( input u64_vector_t addr, u64_vector_t data, int size = 4,
                                  ref int result = _null);
      /*      axi_pkg::resp_t resp;

      m_driver.send_aw( addr[0], 0 );
      m_driver.send_w( data[0], 'hf );
      m_driver.recv_b(  resp );*/

    endtask  // write

    // [master only] generic read(s), blocking
    virtual task automatic readm(input u64_vector_t addr, ref u64_vector_t data, input int size = 4,
                                 ref int result = _null);
      /*  logic [31:0] d;
      axi_pkg::resp_t resp;
      
      m_driver.send_ar( addr[0], 0 );
      m_driver.recv_r( d, resp );

      data[0] = d;*/

    endtask  // readm
  endclass  // CAXI4FullAccessor

  
  class CAXI4MemSlave extends CMonitorableMemory;

    parameter g_AW = 32;
    parameter g_DW = 512;
    parameter g_IW = 4;
    parameter g_UW = 2;

    typedef virtual AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(g_AW),
        .AXI_DATA_WIDTH(g_DW),
        .AXI_ID_WIDTH  (g_IW),
        .AXI_USER_WIDTH(g_UW)
    ) bus_t;


    typedef axi_driver#(g_AW, g_DW, g_IW, g_UW, 1ns, 0ns) driver_t;

    protected driver_t m_driver;


    function new(bus_t bus);
      super.new(g_DW);
      m_driver = new(bus);
    endfunction  // new

    virtual task automatic reset();
      m_driver.reset_slave();
    endtask  // reset


    virtual task automatic run();
      automatic driver_t::b_beat_t b_beat = new;
      automatic driver_t::ax_beat_t aw_beat = new;
      automatic driver_t::w_beat_t w_beat = new;
      automatic bit [g_AW-1:0] w_addr;
      automatic int i;


      forever
      fork
        begin
          m_driver.recv_aw(aw_beat);
          w_addr = aw_beat.ax_addr;

          //	      $display("Got AWADDR %x", aw_beat.ax_addr );
          i = 0;

        end
        begin
          m_driver.recv_w(w_beat);
          m_mem[w_addr] = w_beat.w_data;
          w_addr += (g_DW / 8);
          i++;

          while (!w_beat.w_last) begin
            m_driver.recv_w(w_beat);
            //		   $display("WADDR %x", w_addr);

            m_mem[w_addr] = w_beat.w_data;
            w_addr += (g_DW / 8);
            i++;

          end

          //	      $display("Burst: addr %x count %d", aw_beat.ax_addr, i );

          //	      $display("Got W");


          b_beat.b_id   = aw_beat.ax_id;
          b_beat.b_resp = 0;
          m_driver.send_b(b_beat);

        end
      join


    endtask  // run



  endclass  // CAXI4MemSlave





  class CSimpleIFMemSlave extends CMonitorableMemory;

    parameter g_AW = 32;
    parameter g_DW = 512;

    typedef virtual ISimpleMemWriteIF #(
        .g_AW(g_AW),
        .g_DW(g_DW)
    ) bus_t;

    protected bus_t m_bus;

    function new(bus_t bus);
      super.new(g_DW);
      this.m_bus = bus;
    endfunction  // new

    virtual task automatic reset();
      m_bus.ready <= 0;
      @(posedge m_bus.clk_i);
    endtask  // reset

    virtual task automatic run();
      uint64_t addr;
      const int latency = 3;
      int burst_cnt;

      forever begin
        if (m_bus.req) begin
          addr = m_bus.addr;
          burst_cnt = m_bus.burst_len;

          $display("GotReq [0x%x, burst=%d, last=%d]", addr, burst_cnt, m_bus.last);

          for (int i = 0; i < 3; i++) @(posedge m_bus.clk_i);

          m_bus.ready <= 1;

          while (!m_bus.last && burst_cnt > 0) begin
            if (m_bus.req && m_bus.ready) begin
              $display("Write %x: %x", addr, m_bus.data);

              m_mem[addr*g_DW/8] = m_bus.data;
              addr++;
              burst_cnt--;
            end
            @(posedge m_bus.clk_i);
          end

          m_bus.ready <= 0;
        end
        @(posedge m_bus.clk_i);

      end

    endtask  // run


  endclass  // CSimpleIFMemSlave


endpackage  // axi_drivers




