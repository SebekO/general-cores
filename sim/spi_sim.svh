//------------------------------------------------------------------------------
// CERN BE-CO-HT
// General Cores Library
// https://www.ohwr.org/project/general-cores
//------------------------------------------------------------------------------
//
// unit name: IFACE_SPI, CSPI_Slave
//
// description: Collection of interfaces and classes for
//              implementing SPI testbenches.
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

`ifndef _SPI_SIM
 `define _SPI_SIM

interface IFACE_SPI ();
   logic sclk;
   logic mosi;
   logic miso_in;
   logic miso_out;
   logic cs_n;

   modport master
     (
      output sclk,
      output mosi,
      input  miso_in,
      output cs_n);

   modport slave
     (
      input  sclk,
      input  mosi,
      output miso_out,
      input  cs_n);

   assign miso_in = cs_n?  'bz : miso_out;

endinterface // IFACE_SPI

typedef virtual IFACE_SPI.master viSpiMaster;
typedef virtual IFACE_SPI.slave  viSpiSlave;

class CSPI_Slave;

   protected viSpiSlave spi;
   protected bit shift_reg[];
   protected int size;
   protected int cpol;
   protected int cpha;

   // size defines the size of the slave SPI register
   function new(viSpiSlave spi,
                int size = 8,
                int cpol = 0,
                int cpha = 0);

      int i;

      this.spi  = spi;
      this.size = size;
      this.shift_reg = new[size];
      set_mode(cpol, cpha);

      fork
         spi.miso_out = 0;
         forever @(posedge spi.sclk) begin
            if (spi.cs_n == 1'b0)
              begin
                 spi.miso_out = shift_reg[size-1];
                 for (i = size - 1; i > 0; i--)
                   shift_reg[i] = shift_reg[i-1];
                 shift_reg[0] = spi.mosi;
              end
         end
      join_none

   endfunction // new

   function void set_mode(int cpol, int cpha);
      this.cpol = cpol;
      this.cpha = cpha;
   endfunction // set_mode

   task run();
   endtask // run

   task set_data(input bit data[]);
      shift_reg = data;
   endtask // set_data

   task get_data(ref bit data[]);
      data = shift_reg;
   endtask // set_data

endclass // CSPI_Slave

`endif // _SPI_SIM
