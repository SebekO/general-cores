--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_sync_word_rd
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- description: Testbench for synchronizer for reading a word with an ack.
--
--   Used to transfer a word from the output clock domain to the input clock
--   domain.  The user provided data is constantly read.  When a read request
--   arrives (on the output side), the user data is frozen (not read anymore),
--   and sent to the output side.  A pulse is generated on the output side
--   when the transfer is done, and the data is unfrozen.  A pulse is also
--   generated on the input side.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
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

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.gencores_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_sync_word_rd               --
--=============================================================================

entity tb_gc_sync_word_rd is
  generic (
    g_seed  : natural;
  	g_WIDTH : positive := 8);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_sync_word_rd is

  -- Constants
  constant C_CLK_IN_PERIOD  : time := 10 ns;
  constant C_CLK_OUT_PERIOD : time := 5 ns;

  --Signals
  signal tb_clk_out_i   : std_logic := '1';
  signal tb_rst_out_n_i : std_logic;
  signal tb_clk_in_i    : std_logic := '1';
  signal tb_rst_in_n_i  : std_logic;
  signal tb_data_in_i   : std_logic_vector(g_WIDTH - 1 downto 0) := (others=>'0');
  signal tb_rd_out_i    : std_logic := '0';
  signal tb_ack_out_o   : std_logic;
  signal tb_data_out_o  : std_logic_vector(g_WIDTH - 1 downto 0);
  signal tb_rd_in_o     : std_logic;
  signal stop           : boolean;

  -- Shared variables used for coverage
  shared variable cp_rst_in_i  : covPType;
  shared variable cp_rst_out_i : covPType;

begin
   
  --Unit Under Test
  UUT : entity work.gc_sync_word_rd
  generic map (
    g_WIDTH => g_WIDTH)
  port map (
   	clk_out_i   => tb_clk_out_i,
	  rst_out_n_i => tb_rst_out_n_i,
	  clk_in_i    => tb_clk_in_i,
	  rst_in_n_i  => tb_rst_in_n_i,
	  data_in_i   => tb_data_in_i,
	  rd_out_i    => tb_rd_out_i,
	  ack_out_o   => tb_ack_out_o,
	  data_out_o  => tb_data_out_o,
	  rd_in_o     => tb_rd_in_o);

  -- Input clock/reset generation
  clk_in : process
  begin
	  while not stop loop
	    tb_clk_in_i <= '0';
	    wait for C_CLK_IN_PERIOD/2;
	    tb_clk_in_i <= '1';
	    wait for C_CLK_OUT_PERIOD/2;
	  end loop;
	wait;
  end process clk_in;

  tb_rst_in_n_i <= '0', '1' after 2 * C_CLK_IN_PERIOD;

  -- Output clock/reset
  clk_out : process
  begin
	  while stop = FALSE loop
	    tb_clk_out_i <= '0';
	    wait for C_CLK_OUT_PERIOD/2;
	    tb_clk_out_i <= '1';
	    wait for C_CLK_OUT_PERIOD/2;
	  end loop;
	wait;
  end process clk_out;

  tb_rst_out_n_i <= '0', '1' after 2 * C_CLK_OUT_PERIOD;

  -- Randomized stimulus
  stim : process
	  variable data    : RandomPType;
	  variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while (NOW < 1 ms) loop
	    wait until (rising_edge(tb_clk_in_i) and tb_rst_in_n_i='1');
        if (tb_rd_in_o='1') then
	        tb_rd_out_i <= '1';
        else
          tb_rd_out_i <= '0';
        end if;
	      if (tb_rd_out_i = '1' and tb_clk_in_i = '1') then
	        tb_data_in_i <= data.randSlv(g_WIDTH);
        end if;
	      ncycles := ncycles + 1;
	    end loop;
	    report "Number of simulation cycles = " & to_string(ncycles);
      report "Test PASS!";
	    stop <= TRUE;
	    wait;
    end process stim;

  --------------------------------------------------------------------------------
  --                           Assertions - Self Checking                       --
  --------------------------------------------------------------------------------

	--Assertions   
  self_check : process
  begin
    while not stop loop
      wait until (rising_edge(tb_ack_out_o));
      assert (tb_data_in_i = tb_data_out_o)
        report "data mismatch" severity failure;
    end loop;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
  InitCoverage: process 
  begin        
    cp_rst_in_i.AddBins("input reset has been asserted", ONE_BIN);
	  cp_rst_out_i.AddBins("output reset has been asserted", ONE_BIN);
    wait;
  end process InitCoverage;

  Sample_rst_in: process
  begin
    loop
      wait on tb_rst_in_n_i;
      cp_rst_in_i.ICover (to_integer(tb_rst_in_n_i = '1'));
    end loop;
  end process;

  sample_rst_out : process
  begin
    loop
      wait on tb_rst_out_n_i;
	    cp_rst_out_i.ICover (to_integer(tb_rst_out_n_i = '1'));
    end loop;
  end process;

  CoverReport: process
  begin
    wait until STOP;
  	cp_rst_in_i.writebin;
	  cp_rst_out_i.writebin;
  end process;

end tb;
