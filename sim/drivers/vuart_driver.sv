
 
package vuart_driver_pkg;

`include "gencores_sim_defs.svh"

import gencores_sim_pkg::*;

class VUARTDriver;
   CBusAccessor m_acc;
   uint64_t m_base;
   string m_current;
   
   function new ( CBusAccessor acc, uint64_t base );
      m_acc = acc;
      m_base = base;
   endfunction

   task update();
      int c_reg_host_rdr = 'h14;
      int c_host_rdr_ready = 'h100;
      uint64_t rdr;
      
      m_acc.read (m_base + c_reg_host_rdr, rdr);

//      if(rdr != 0)
//	$display("rdr %x", rdr);
      
      if (rdr & c_host_rdr_ready)
	begin
	   rdr &= 'hff;
	   $display("RX %c", rdr);
	   
	   if ( rdr == 13 || rdr == 10 )
	     begin
		$display ("VUART: %s", m_current);
		m_current = "";
	     end else
	       m_current = $sformatf("%s%c", m_current, rdr & 'hff);
	end
      
   endtask // update

endclass // VUARTDriver

endpackage
