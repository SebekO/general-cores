//------------------------------------------------------------------------------
// CERN BE-CEM-EDL
// General Cores Library
// https://www.ohwr.org/projects/general-cores
//------------------------------------------------------------------------------
//
// unit name: IVHDWishboneMaster
//
// description: Wishbone master BFM with interface compatibile with the VHDL
//              side of gencores (wishbone_pkg)
//
//------------------------------------------------------------------------------
// Copyright CERN 2010-2019
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

`ifndef __VHD_WISHBONE_MASTER_INCLUDED
 `define __VHD_WISHBONE_MASTER_INCLUDED

`include "gencores_sim_defs.svh"
`include "if_wb_master.svh"

import wishbone_pkg::*;

interface IVHDWishboneMaster
  (
   input wire clk_i,
   input wire rst_n_i
   );

   parameter g_addr_width 	   = 32;
   parameter g_data_width 	   = 32;

   typedef virtual IWishboneMaster VIWishboneMaster;
   
   IWishboneMaster #(g_addr_width, g_data_width) TheMaster (clk_i, rst_n_i);

   t_wishbone_master_in in;
   t_wishbone_master_out out;

   modport master
     (
      input  in,
      output out
      );
   
   assign out.cyc = TheMaster.cyc;
   assign out.stb = TheMaster.stb;
   assign out.we = TheMaster.we;
   assign out.sel = TheMaster.sel;
   assign out.adr = TheMaster.adr;
   assign out.dat = TheMaster.dat_o;
   
   assign TheMaster.ack = in.ack;
   assign TheMaster.stall = in.stall;
   assign TheMaster.rty = in.rty;
   assign TheMaster.err = in.err;
   assign TheMaster.dat_i = in.dat;


   function automatic CWishboneAccessor get_accessor();
      automatic CWishboneAccessor acc = TheMaster.get_accessor();
      return acc;
   endfunction // get_accessor

   initial begin
      @(posedge rst_n_i);
      @(posedge clk_i);

      TheMaster.settings.addr_gran = BYTE;
      TheMaster.settings.cyc_on_stall = 1;
   end
   
      
endinterface // IVHDWishboneMaster

`endif //  `ifndef __VHD_WISHBONE_MASTER_INCLUDED
