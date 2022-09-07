-------------------------------------------------------------------------------
-- Title      : Testbench for Reset synchronizer and generator
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_gc_reset.vhd
-- Company    : CERN (BE-CEM-EDL)
-- Author     : Konstantinos Blantos
-- Platform   : FPGA-generics
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Copyright (c) 2012-2017 CERN
--
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the "License") (which enables you, at your option,
-- to treat this file as licensed under the Apache License 2.0); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://solderpad.org/licenses/SHL-0.51.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_reset is
  generic (
    g_seed      : natural;
    g_clocks    : natural := 2;
    g_logdelay  : natural := 4;
    g_syncdepth : natural := 4);
end entity;

architecture tb of tb_gc_reset is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;
  constant C_LOCKED_DONE: unsigned(g_logdelay-1 downto 0):=(others=>'1');

  -- signals
  signal tb_free_clk_i : std_logic;
  signal tb_locked_i   : std_logic := '1'; -- All the PLL locked signals ANDed together
  signal tb_clks_i     : std_logic_vector(g_clocks-1 downto 0);
  signal tb_rstn_o     : std_logic_vector(g_clocks-1 downto 0);
  signal stop          : boolean;

  subtype t_sync_chains is std_logic_vector(g_syncdepth-1 downto 0);
  type t_chains is array (natural range <>) of t_sync_chains;

  signal s_sync_chains : t_chains(g_clocks-1 downto 0) := (others=>(others=>'0'));
  signal s_locked_cnt  : unsigned(g_logdelay-1 downto 0) := (others=>'0');
  signal s_master_rstn : std_logic := '0';
  signal s_rstn_o      : std_logic_vector(g_clocks-1 downto 0) := (others=>'0');

  -- Shared variables used for coverage
  shared variable cp_master_rstn : covPType;
  shared variable cp_rstn_o      : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_reset
  generic map (
    g_clocks    => g_clocks,
    g_logdelay  => g_logdelay,
    g_syncdepth => g_syncdepth)
  port map (
    free_clk_i => tb_free_clk_i,
    locked_i   => tb_locked_i,
    clks_i     => tb_clks_i,
    rstn_o     => tb_rstn_o);

  -- Clock generation
	clk_proc : process
	begin
    while not stop loop
      tb_free_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_free_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
		wait;
	end process clk_proc;

  -- Stimulus
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 8 ms loop
      wait until (rising_edge(tb_free_clk_i));
	    tb_locked_i <= data.randSlv(1)(1);
      tb_clks_i   <= data.randSlv(g_clocks);
	    ncycles     := ncycles + 1;
	  end loop;
	  report "Number of simulation cycles = " & to_string(ncycles);
	  stop <= TRUE;
    report "Test PASS!";
	  wait;
  end process stim;

  --------------------------------------------------------------------------------
  -- Reproduce the RTL behavior for comparison to real RTL
  --------------------------------------------------------------------------------

  -- reproduce the asynchronous reset
  process(tb_free_clk_i, tb_locked_i)
  begin
    if tb_locked_i = '0' then
      s_master_rstn <= '0';
      s_locked_cnt  <= (others=>'0');
    else
      if rising_edge(tb_free_clk_i) then
        if s_locked_cnt = C_LOCKED_DONE then
          s_master_rstn <= '1';
        else
          s_master_rstn <= '0';
          s_locked_cnt <= s_locked_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- generate sync chains for each clock domain
  sync_chains : for i in 0 to g_clocks-1 generate
    process(tb_clks_i(i))
    begin
      if rising_edge(tb_clks_i(i)) then
        s_sync_chains(i) <= s_master_rstn & s_sync_chains(i)(g_syncdepth-1 downto 1);
      end if;
    end process;
    s_rstn_o(i) <= s_sync_chains(i)(0);
  end generate; 

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------

  compare_outputs : process(tb_free_clk_i)
  begin
    if rising_edge(tb_free_clk_i) then
      assert (tb_rstn_o = s_rstn_o)
        report "Output mimatch" severity failure;
    end if;
  end process; 

  --------------------------------------------------------------------------------
  --                              Coverage                                      --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
	init_coverage : process
	begin
    cp_master_rstn.AddBins("Master reset asserted", ONE_BIN);
    cp_rstn_o.AddBins("Output reset asserted", ONE_BIN);
		wait;
	end process init_coverage;

  -- sample coverpoints for reset
  sample_rst_n_i : process
	begin
		loop
			wait until (rising_edge(tb_free_clk_i)); 
			cp_master_rstn.ICover(to_integer(s_master_rstn = '1'));
		end loop;
	end process;

  -- sample coverpoints for input data
  sample_rstn_o : process(tb_free_clk_i)
  begin
    for i in 0 to g_clocks-1 loop
      if rising_edge(tb_free_clk_i) then
        cp_rstn_o.ICover(to_integer(s_rstn_o(i)='1'));
      end if;
    end loop;
  end process;

  -- Coverage report 
  cover_report: process
	begin
		wait until stop;
    cp_master_rstn.writebin;
    cp_rstn_o.writebin;
	end process;

end tb;
