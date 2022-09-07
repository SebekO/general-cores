--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author : Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   tb_gc_reset_multi_aasd
--
-- description: Testbench for multiple clock domain reset generator and 
--              synchronizer with Asynchronous Assert and 
--              Syncrhonous Deassert (AASD). 
--
--------------------------------------------------------------------------------
-- Copyright CERN 2018
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

--OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_reset_multi_aasd is
  generic (
    g_seed    : natural;
  	-- number of clock domains
  	g_CLOCKS  : natural := 2;
    -- Number of clock ticks (per domain) that the input reset must remain
    -- deasserted and stable before deasserting the reset output(s)
  	g_RST_LEN : natural := 1);
end entity;

architecture tb of tb_gc_reset_multi_aasd is

  -- Constants
	constant C_CLK_PERIOD : time := 10 ns;

	-- Signals
	signal tb_arst_i  : std_logic := '0';
	signal tb_clks_i  : std_logic_vector(g_CLOCKS-1 downto 0) := (others=>'0');
	signal tb_rst_n_o : std_logic_vector(g_CLOCKS-1 downto 0);
  signal stop       : boolean;
  signal s_cnt_rst  : unsigned(g_RST_LEN-1 downto 0) := (others=>'0');
  signal s_cnt_clks : unsigned(g_CLOCKS-1 downto 0)  := (others=>'0');
  signal s_rst      : std_logic;

  subtype t_rst_chain is std_logic_vector(g_RST_LEN-1 downto 0);
  type t_rst_chains is array(natural range <>) of t_rst_chain;
  signal s_rst_chains : t_rst_chains(g_CLOCKS-1 downto 0) := (others => (others => '0'));

begin

	--Unit Under Test
	UUT : entity work.gc_reset_multi_aasd
	generic map (
		g_CLOCKS  => g_CLOCKS,
		g_RST_LEN => g_RST_LEN)
	port map (
		arst_i  => tb_arst_i,
		clks_i  => tb_clks_i,
		rst_n_o => tb_rst_n_o);

	--Stimulus
	stim : process
		variable ncycles : natural;
    variable data    : RandomPType;
	begin
    data.InitSeed(g_seed);
		report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 1 ms loop
      wait for C_CLK_PERIOD;
			tb_clks_i <= data.randSlv(g_CLOCKS);
      tb_arst_i <= data.randSlv(1)(1);           
			ncycles   := ncycles + 1;
		end loop;
		report "Number of simulation cycles = " & to_string(ncycles);
		stop <= TRUE;
    report "Test PASS!";
		wait;
	end process;
    
  --------------------------------------------------------------------------------
  --                            Assertions                                      --
  --------------------------------------------------------------------------------

  -- Assertion 1: checking the values of the generics
  assert (g_CLOCKS >0 and  g_RST_LEN>0)
    report "g_CLOCKS and g_RST_LEN should be greater than zero"
    severity failure;

  -- Assertion 2: for one clock domain
  single_clk_domain : if (g_CLOCKS = 1) generate
    assert_check : for I in g_CLOCKS-1 downto 0 generate    
      check : process(tb_clks_i, tb_arst_i)
      begin
        if tb_arst_i = '0' then
          if tb_clks_i(i)='0' then
            s_cnt_rst <= s_cnt_rst + 1;
            if s_cnt_rst = g_RST_LEN then
              s_cnt_rst <= (others=>'0');
              assert (tb_rst_n_o(i) = '1')
                report "wrong" severity failure;
            end if;
          end if;
        else 
          s_cnt_rst <= (others=>'0');
        end if;
      end process;
    end generate;
  end generate;

  s_rst <= tb_arst_i;

  -- Assertion 3: for many clock domains
  many_clk_domains : if (g_CLOCKS > 1) generate
    assert_check : for I in g_CLOCKS-1 downto 0 generate
      
      check : process(tb_clks_i, s_rst)
      begin
        if s_rst = '1' then --if NOT reset
          s_rst_chains(i) <= (others=>'0');
        elsif rising_edge(tb_clks_i(i)) then 
          s_rst_chains(i) <= '1' & s_rst_chains(i)(g_RST_LEN-1 downto 1);
        end if;
      end process;
      
      process(tb_clks_i, s_rst)
      begin
        if s_rst = '0' then
          if rising_edge(tb_clks_i(i)) then
            assert (s_rst_chains(i)(0) = tb_rst_n_o(i))
              report "Wrong" severity warning;
          end if;
        end if;
      end process;

    end generate;
  end generate;    

end tb;
