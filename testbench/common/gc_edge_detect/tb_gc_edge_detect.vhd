--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author : Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   tb_gc_edge_detect
--
-- description: testbench for simple edge detector
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

entity tb_gc_edge_detect is
  generic (
    g_seed       : natural;
  	g_ASYNC_RST  : boolean := FALSE;
  	g_PULSE_EDGE : string  := "positive"; 
    g_CLOCK_EDGE : string  := "positive");
end entity;

architecture tb of tb_gc_edge_detect is

  -- Constants
	constant C_CLK_PERIOD : time := 10 ns;

	-- Signals 
	signal tb_clk_i   : std_logic;
	signal tb_rst_i   : std_logic;
	signal tb_d_i     : std_logic := '0';
	signal tb_pulse_o : std_logic;
  signal stop       : boolean;
	
  -- Shared variables, used for coverage
  shared variable cp_rst_i : covPType;

begin
	
  -- Unit Under Test
	UUT : entity work.gc_edge_detect
	generic map (
		g_ASYNC_RST  => g_ASYNC_RST,
		g_PULSE_EDGE => g_PULSE_EDGE,
		g_CLOCK_EDGE => g_CLOCK_EDGE)
	port map (
		clk_i   => tb_clk_i,
		rst_n_i => tb_rst_i,
		data_i  => tb_d_i,
		pulse_o => tb_pulse_o);

	-- Clock generation
	clk_proc : process
	begin
		while STOP = FALSE loop
			tb_clk_i <= '1';
			wait for C_CLK_PERIOD/2;
			tb_clk_i <= '0';
			wait for C_CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_proc;

	-- Reset generation
  tb_rst_i <= '0', '1' after 4*C_CLK_PERIOD;
	
	-- Stimulus
	stim : process
		variable data : RandomPType;
		variable ncycles : natural;
	
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
		while NOW < 4 ms loop
			wait until (rising_edge(tb_clk_i) and tb_rst_i = '1');
			tb_d_i  <= data.randSlv(1)(1);
			ncycles := ncycles + 1;
		end loop;
		report "Number of simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
		stop <= TRUE;
		wait;
	end process;

	--sets up coverpoint bins
	init_coverage : process
	begin
		cp_rst_i.AddBins("reset has asserted", ONE_BIN);
		wait;
	end process init_coverage;

  --Assertion to check that the width of the output pulse
  --is asserted for only one clock cycle
  one_clk_width : process
  begin
    if rising_edge(tb_clk_i) then
      if tb_pulse_o = '1' then
        wait for C_CLK_PERIOD;
        assert (tb_pulse_o = '0')
          report "output pulse remains high for more than one clock"
          severity failure;
      end if;
    end if;
    wait;
  end process;   

	--Assertion to check that output is the same as input
	--after one clock cycle
	check_output : process
	begin
		if rising_edge(tb_clk_i) then
			if tb_d_i /= tb_pulse_o then
				wait for C_CLK_PERIOD;
				assert (tb_d_i = tb_pulse_o)
				  report "Input and Output signals are different" 
				  severity failure;
			else
				wait for C_CLK_PERIOD;
				assert (tb_d_i /= tb_pulse_o)
				  report "Input and Output signals still the same"
				  severity failure;
			end if;
		end if;
		wait;
	end process check_output;

	sample : process
	begin
		loop
			wait on tb_rst_i;
			wait for C_CLK_PERIOD;
			--sample the coverpoints
			cp_rst_i.ICover(to_integer(tb_rst_i = '1'));
		end loop;
	end process sample;

	cover_report: process
	begin
		wait until stop;
		cp_rst_i.writebin;
	end process;

end tb;
