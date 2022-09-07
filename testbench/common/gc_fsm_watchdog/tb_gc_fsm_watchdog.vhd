--==============================================================================
-- CERN (BE-CEM-EDL)
-- Testbench for Finite State Machine Watchdog Timer
--==============================================================================
--
-- author: Konstantinos Blantos
--
-- date of creation: 2021-11-225
--
-- version: 1.0
--
-- description:
--
-- references: from the file gc_fsm_watchdog
--
--==============================================================================
-- GNU LESSER GENERAL PUBLIC LICENSE
--==============================================================================
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version. This source is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
-- of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details. You should have
-- received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-2.1.html
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_fsm_watchdog is
  generic (
    g_seed    : natural;
    g_wdt_max : positive := 65535);
end entity;

architecture tb of tb_gc_fsm_watchdog is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  --Signals
  signal tb_clk_i     : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_wdt_rst_i : std_logic := '0';
  signal tb_fsm_rst_o : std_logic;
  signal stop         : boolean;
  signal s_wdt_cnt    : unsigned(f_log2_ceil(g_wdt_max)-1 downto 0) := (others=>'0');

  -- Shared variables, used for coverage
  shared variable cp_rst_n_i   : covPType;
  shared variable cp_fsm_rst_o : covPType;

begin

  --Unit Under Test
  UUT : entity work.gc_fsm_watchdog
  generic map(
    g_wdt_max => g_wdt_max)
  port map (
    clk_i     => tb_clk_i,
    rst_n_i   => tb_rst_n_i,
    wdt_rst_i => tb_wdt_rst_i,
    fsm_rst_o => tb_fsm_rst_o);

  -- Clock generation
  clk_i_process : process
  begin
    while not stop loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
    
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while NOW < 4 ms loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_wdt_rst_i <= data.randSlv(1)(1);
      ncycles      := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------
    
  -- Check that the output becomes one when the counter reaches the higher value
  check_output : process
  begin
    wait until rising_edge(tb_clk_i);
    if (tb_rst_n_i = '0' or tb_wdt_rst_i = '1') then
      s_wdt_cnt <= (others=>'0');
    else
      s_wdt_cnt <= s_wdt_cnt + 1;
      if (s_wdt_cnt = g_wdt_max-1) then
        wait for C_CLK_PERIOD;
        assert (tb_fsm_rst_o = '1') 
          report "fsm reset is not HIGH" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------
   
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset has asserted", ONE_BIN);
    cp_fsm_rst_o.AddBins("Output fsm reset asserted",ONE_BIN);
    wait;
  end process;
   
  -- Sample the coverpoints
  sample_rst_cov : process
  begin
    loop
      wait on tb_rst_n_i;
      cp_rst_n_i.ICover(to_integer(tb_rst_n_i = '1'));
    end loop;
  end process;

  sample_out_pulse : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      if s_wdt_cnt = g_wdt_max-1 then
        cp_fsm_rst_o.ICover(to_integer(tb_fsm_rst_o = '1'));
      end if;
    end loop;
  end process;

  -- Coverage report
  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_fsm_rst_o.Writebin;
  end process;
 
end tb;
 


