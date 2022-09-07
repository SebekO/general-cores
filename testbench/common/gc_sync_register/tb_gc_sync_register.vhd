--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author:  Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   gc_sync_register
--
-- description: Testbench for parametrized synchronizer.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2014-2018
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
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_sync_register              --
--=============================================================================

entity tb_gc_sync_register is
	generic (
    g_seed  : natural;
		g_WIDTH : integer := 8);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_sync_register is

  -- Constants
	constant C_CLK_PERIOD : time := 10 ns;
	
  -- Signals
	signal tb_clk_i 	  : std_logic;
	signal tb_rst_n_a_i : std_logic;
	signal tb_d_i		    : std_logic_vector(g_WIDTH-1 downto 0) := (others=>'0');
	signal tb_q_o		    : std_logic_vector(g_WIDTH-1 downto 0);
  signal s_data_o     : std_logic_vector(g_WIDTH-1 downto 0) := (others=>'0');
  signal s_data_0     : std_logic_vector(g_WIDTH-1 downto 0) := (others=>'0');
	signal stop         : boolean;

begin
	
	-- Unit Under Test
	UUT : entity work.gc_sync_register
	generic map (
		g_WIDTH => g_WIDTH)
	port map (
		clk_i 	  => tb_clk_i,
		rst_n_a_i => tb_rst_n_a_i,
		d_i 	  => tb_d_i,
		q_o 	  => tb_q_o);

	clk_i : process
	begin
		while stop = FALSE loop
			tb_clk_i <= '1';
			wait for C_CLK_PERIOD/2;
			tb_clk_i <= '0';
			wait for C_CLK_PERIOD/2;
		end loop;
		wait;
	end process;

	tb_rst_n_a_i <= '0', '1' after 2 * C_CLK_PERIOD;

  --Stimulus
	stim : process
		variable ncycles : natural;
		variable data    : RandomPType;
	begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
		while (NOW < 1 ms) loop
			wait until (rising_edge(tb_clk_i));
			tb_d_i  <= data.randSlv(g_WIDTH);
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

  -- Assertion to verify that the
  -- output data is the same as the input
  data_check_in : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      s_data_0 <= tb_d_i;
      s_data_o <= s_data_0;
      assert (s_data_o = tb_q_o)
        report "data mismatch" severity failure;
    end if;
  end process;

end tb;

