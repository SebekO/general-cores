--------------------------------------------------------------------------------
-- Title      : TB for Generic generation of synchronous reset for one clock domain
--------------------------------------------------------------------------------
-- File       : tb_gc_single_reset_gen.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
--------------------------------------------------------------------------------
-- Description:
--
-- This module is the testbench of gc_single_reset_gen. The RTL module, 
-- generates a synchronous negative pulse reset from a vector of asynchronous 
-- inputs (e.g. the PCIe bus powerup reset and SPEC button reset).
--
-- It was importent from wr-cores/top/spec_1_1/wr_core_demo/spec_reset_gen.vhd
--
--------------------------------------------------------------------------------
--
-- Copyright (c) 2016 CERN/BE-CO-HT
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_single_reset_gen is
  generic (
    g_seed : natural;
    g_out_reg_depth : natural := 4;
    g_rst_in_num    : natural := 5);
end entity;

architecture tb of tb_gc_single_reset_gen is

  -- Constants 
  constant C_CLK_PERIOD : time := 10 ns;
  constant ONES         : std_logic_vector(g_rst_in_num-1 downto 0)   := (others => '1');    

  -- Signals
  signal tb_clk_i             : std_logic;
  signal tb_rst_signals_n_a_i : std_logic_vector(g_rst_in_num-1 downto 0) := (others=>'0');
  signal tb_rst_n_o           : std_logic;
  signal stop                 : boolean;
  
  type t_rst_signals_array is array (0 to 3) of std_logic_vector(g_rst_in_num-1 downto 0);
  signal s_rst_signals_arr : t_rst_signals_array;
  
  signal s_cnt_powerup : unsigned(7 downto 0) := (others=>'0');
  signal s_powerup     : std_logic; 
  signal s_rst_n       : std_logic; 
  signal s_rst_n_o     : std_logic_vector(g_out_reg_depth-1 downto 0):= (others => '0');  

  -- Shared variable, used for coverage
  shared variable cp_powerup : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_single_reset_gen
  generic map (
    g_out_reg_depth => g_out_reg_depth,
    g_rst_in_num  => g_rst_in_num)
  port map (
    clk_i             => tb_clk_i,
    rst_signals_n_a_i => tb_rst_signals_n_a_i,
    rst_n_o           => tb_rst_n_o);

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

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until rising_edge(tb_clk_i);
      tb_rst_signals_n_a_i <= data.randSlv(g_rst_in_num);
      ncycles              := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --              Stimulate the behavior of the RTL module                      --
  --------------------------------------------------------------------------------
    
  -- generate the synchronized input reset signals
  -- 3 clock cycles delay due to gc_sync_ffs
  process (tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      s_rst_signals_arr(0) <= tb_rst_signals_n_a_i;
      for i in 0 to 2 loop
        s_rst_signals_arr(i+1) <= s_rst_signals_arr(i);
      end loop;
    end if;
  end process;

  -- powerup reset
  process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if s_cnt_powerup /= X"FF" then
        s_cnt_powerup <= s_cnt_powerup + 1;
        s_powerup <= '0';
      else
        s_powerup <= '1';
      end if;
    end if;
  end process;

  s_rst_n <= '1' when (s_powerup='1' and s_rst_signals_arr(2)= ONES) else '0';
    
  -- reset after flip-flops
  -- final reset is s_rst_n_o(0)
  process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      s_rst_n_o <= s_rst_n & s_rst_n_o(g_out_reg_depth-1 downto 1);
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                  Assertions                                --
  --------------------------------------------------------------------------------

  -- Check that the number of f/f before the final signals' output is valid
  assert (g_out_reg_depth > 0)
    report "Invalid output register depth" severity failure;

  -- Check that number of asynchronous reset signals is valid
  assert (g_rst_in_num > 0)
    report "Invalid number of async reset signals" severity failure;

  check_output : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      assert (s_rst_n_o(0) = tb_rst_n_o)
        report "Reset mismatch" severity failure;
    end if;
  end process;

  no_output_before_powerup : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if s_powerup = '0' then
        assert (tb_rst_n_o = '0')
          report "Reset asserted before powerup" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                 Coverage                                   --
  --------------------------------------------------------------------------------
    
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_powerup.AddBins("powerup has done", ONE_BIN);
    wait;
  end process;
   
  -- Sample the coverpoints
  sample_powerup_cov : process
  begin
    loop
      wait until (rising_edge(s_powerup));
      cp_powerup.ICover(to_integer(s_powerup='1'));
    end loop;
  end process;

  -- Coverage report
  cover_report : process
  begin
    wait until stop;
    cp_powerup.Writebin;
  end process;
   
end tb;

