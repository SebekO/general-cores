`ifndef IF_WISHBONE_ACCESSOR_SV
`define IF_WISHBONE_ACCESSOR_SV

`include "if_wishbone_types.svh"

import gencores_sim_pkg::CBusAccessor;

virtual class CWishboneAccessor extends CBusAccessor;

   static int _null  = 0;
   protected wb_cycle_type_t m_cycle_type;

   function new();
      m_cycle_type  = CLASSIC;
      m_default_xfer_size = 4;
   endfunction // new

   virtual task automatic set_mode(wb_cycle_type_t mode);
      m_cycle_type  = mode;
   endtask // set_mode
   
   
   // [slave only] checks if there are any transactions in the queue 
   virtual function automatic int poll();
      return 0;
   endfunction // poll

   // [slave only] adds a simulation event (e.g. a forced STALL, RETRY, ERROR)
   // evt = event type (STALL, ERROR, RETRY)
   // behv = event behavior: DELAYED - event occurs after a predefined delay (dly_start)
   //                        RANDOM - event occurs randomly with probability (prob)
   // These two can be combined (random events occuring after a certain initial delay)
   // DELAYED events can be repeated (rep_rate parameter)
   virtual task automatic add_event(wba_sim_event_t evt, wba_sim_behavior_t behv, int dly_start, real prob, int rep_rate);

   endtask // add_event


   // [slave only] gets a cycle from the queue
   virtual task  automatic get(ref wb_cycle_t xfer);
      
   endtask // get

   // [master only] executes a cycle and returns its result
   virtual task  automatic put(ref wb_cycle_t xfer);

   endtask // put
   
   virtual function int idle();
      return 1;
   endfunction // idle
   
   // [master only] generic write(s), blocking
   virtual task  automatic writem(u64_vector_t addr, u64_vector_t data, int size = 4, ref int result = _null);
      wb_cycle_t cycle;
      int i;

      cycle.ctype  = m_cycle_type;
      cycle.rw  = 1'b1;
      
      for(i=0;i < addr.size(); i++)
        begin
           wb_xfer_t xfer;
           xfer.a     = addr[i];
           xfer.d     = data[i];
           xfer.size  = size;
           cycle.data.push_back(xfer);
        end

//      $display("DS: %d", cycle.data.size());

      put(cycle);
      // wait for the transfer completion notification to avoid getting the result of the wrong transfer
      // in case multiple threads are calling readm()/writem() in parallel.
      @cycle.done;
      get(cycle);
      result  = cycle.result;
      
   endtask // write

   // [master only] generic read(s), blocking
   virtual task  automatic readm(u64_vector_t addr, ref u64_vector_t data,input int size = 4, ref int result = _null);
      wb_cycle_t cycle;
      int i;

      cycle.ctype  = m_cycle_type;

      cycle.rw  = 1'b0;
      
      for(i=0;i < addr.size(); i++)
        begin
           wb_xfer_t xfer;
           xfer.a     = addr[i];
           xfer.size  = size;
           cycle.data.push_back(xfer);
        end

      put(cycle);
      // wait for the transfer completion notification to avoid getting the result of the wrong transfer
      // in case multiple threads are calling readm()/writem() in parallel.
      @cycle.done;
      get(cycle);

      for(i=0;i < addr.size(); i++)
        data[i]  = cycle.data[i].d;
      
      result     = cycle.result;

   endtask // readm

   virtual task  automatic read(uint64_t addr, ref uint64_t data, input int size = 4, ref int result = _null);
      automatic u64_vector_t aa = '{ addr }, da = '{ 0 };
      readm(aa, da, size, result);
      data  = da[0];
   endtask

   virtual task  automatic write(uint64_t addr, uint64_t data, int size = 4, ref int result = _null);
      automatic u64_vector_t aa = '{ addr }, da = '{ data };
      writem(aa, da, size, result);
   endtask
   
endclass // CWishboneAccessor

static int seed = 0;

function automatic int probability_hit(real prob);
   real rand_val;
   rand_val 	= real'($dist_uniform(seed, 0, 1000)) / 1000.0;
      
   if(rand_val < prob)
     return 1;
   else
     return 0;
    
endfunction // probability_hit


`endif //  `ifndef IF_WISHBONE_ACCESSOR_SV

