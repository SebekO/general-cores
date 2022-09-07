--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author : Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   tb_gc_sync
--
-- description: testbench for Elementary synchronizer chain using two flip-flops
--
--------------------------------------------------------------------------------
-- Copyright CERN 2014-2020
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;


entity tb_gc_sync is
  generic (
    g_seed      : natural;
	  g_SYNC_EDGE : string := "positive");
end entity;


architecture tb of tb_gc_sync is
	
	-- Constants
	constant C_CLK_PERIOD : time := 10 ns;

	-- Signals
	signal tb_clk_i : std_logic;
	signal tb_rst_i : std_logic;
	signal tb_d_i   : std_logic := '0';
	signal tb_q_o   : std_logic;
  signal stop     : boolean;

  -- Shared variables, used for coverage
  shared variable cp_rst_i : covPType;    
     
begin
	
  --Unit Under Test
	UUT : entity work.gc_sync
	generic map (
		g_SYNC_EDGE => g_SYNC_EDGE)
	port map (
  	clk_i     => tb_clk_i,
		rst_n_a_i => tb_rst_i,
		d_i 	  => tb_d_i,
		q_o 	  =>  tb_q_o);

   --Clock generation
  clk_i_process : process
  begin
    while not stop loop
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;
  
  -- Reset generation  
  tb_rst_i <= '0', '1' after 2*C_CLK_PERIOD;

   -- Randomized stimulus
   Stim: process
     variable data : RandomPType;
     variable ncycles : natural;
   begin
     data.InitSeed(g_seed);
     report "[STARTING] with seed = " & to_string(g_seed);
     while NOW < 2 ms loop
       wait until rising_edge(tb_clk_i);
       tb_d_i  <= data.RandSlv(1)(1);
       nCycles := nCycles + 1;
     end loop;
     report "Number of simulation cycles = " & to_string(nCycles);
     STOP <= TRUE;
     report "Test PASS";
     wait;
   end process Stim;


   -------------------------------------------------------------------------------
   --                           Assertions                                      --
   -------------------------------------------------------------------------------

   -- Always checking the delay of the output to be 2 clock cycles
   check_output : process
   begin
     if rising_edge(tb_clk_i) then
       if tb_d_i = '1' then
         wait for 2*C_CLK_PERIOD;
         assert (tb_q_o = '1')
           report "output not asserted after two clocks" severity failure;
       else
         wait for 2*C_CLK_PERIOD;
         assert (tb_q_o = '0')
           report "output not de-asserted after two clocks" severity failure; 
       end if;
     end if;
     wait;
   end process;

   -------------------------------------------------------------------------------
   --                            Coverage                                       --
   -------------------------------------------------------------------------------

   --sets up coverpoint bins
   InitCoverage: process 
   begin        
     cp_rst_i.AddBins("reset has asserted", ONE_BIN);
     wait;
   end process InitCoverage;

   Sample: process
   begin
     loop
       wait on tb_rst_i;
         cp_rst_i.ICover (to_integer(tb_rst_i = '1'));
     end loop;
   end process Sample;

   CoverReport: process
   begin
     wait until STOP;
     cp_rst_i.writebin;
     report "PASS";
   end process;


end tb;
