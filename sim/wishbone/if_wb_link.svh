//------------------------------------------------------------------------------
// CERN BE-CEM-EDL
// General Cores Library
// https://www.ohwr.org/projects/general-cores
//------------------------------------------------------------------------------
//
// unit name: IWishboneLink
//
// description: A generic Wishbone B4 interface definition.
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

interface IWishboneLink;

   parameter g_data_width 	   = 32;
   parameter g_addr_width 	   = 32;
   

   wire [g_addr_width - 1 : 0] adr;
   wire [g_data_width - 1 : 0] dat_o;
   wire [g_data_width - 1 : 0] dat_i;
   wire [(g_data_width/8)-1 : 0] sel; 
   wire ack;
   wire stall;
   wire err;
   wire rty;
   wire	cyc;
   wire stb;
   wire we;
   
   modport slave
     (
      output adr,
      output dat_o,
      input dat_i,
      output sel,
      output cyc,
      output stb,
      output we,
      input ack,
      input stall,
      input err,
      input rty
      );

   modport master
     (
      input adr,
      input dat_o,
      output dat_i,
      input sel,
      input cyc,
      input stb,
      input we,
      output ack,
      output stall,
      output err,
      output rty
      );

endinterface // IWishboneLink
