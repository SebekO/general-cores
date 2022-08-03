package lm32_mcs_driver_pkg;

`include "gencores_sim_defs.svh"

import gencores_sim_pkg::*;

class LM32MCSDriver;

   CBusAccessor m_acc;
   uint64_t m_base;

   const uint64_t c_reg_csr = 'h0;
   const uint64_t c_reg_udata = 'h4;
   const uint64_t c_reg_uaddr = 'h8;
   
   function new ( CBusAccessor acc, uint64_t base );
      m_acc = acc;
      m_base = base;
   endfunction // new

   task automatic reset();
      $error("Called reset!");
      
      m_acc.write( m_base + c_reg_csr, 0 ); // reset
      m_acc.write( m_base + c_reg_csr, 1 ); // un-reset
   endtask // reset

   task automatic load_firmware( string filename );
      int fd, nread, addr = 0;
      uint32_t tmp;
      uint64_t tmp2;
      
      m_acc.write( m_base + c_reg_csr, 0 ); // reset

      fd = $fopen(filename, "rb");

      $display("lm32_mcs: loading %s", filename );
      
      while(!$feof(fd))
	begin
	   nread = $fread( tmp, fd );
	   $display("%x %d", tmp, nread);
	   m_acc.write( m_base + c_reg_uaddr, addr );
	   m_acc.write( m_base + c_reg_udata, tmp );
//	   m_acc.write( m_base + c_reg_uaddr, addr );
//	   m_acc.read( m_base + c_reg_udata, tmp2);
//	   if(tmp != tmp2)
//	     $error("verify failed %x %x", tmp, tmp2);
	   
	   addr++;
	end
      
      
      $fclose(fd);

      m_acc.write( m_base + c_reg_csr, 1 ); // un-reset
      endtask // load_firmware

endclass // LM32MCSDriver

endpackage