--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- general-cores
-- https://www.ohwr.org/project/general-cores
--------------------------------------------------------------------------------
--
-- unit name  : tb_gc_async_counter_diff.vhd
-- author     : Konstantinos Blantos
-- description: Testbench for gc_async_counter_diff
-- 
-- The module counts pulses on inc_i and dec_i inputs. Each input can be
-- in its own clock domain. The module outputs difference in the number of
-- pulses counted on inc_i and dec_i. The output is in the clock domain
-- selected with the g_output_clock generic (that of inc_i or of dec_i).
-- 
-- Internally, Grey Codes are used and count encoded with Grey Code is
-- resynchronized to the output clock domain. Therefore, the output
-- is provided few clock cycles after pulse actually occured.
--
--------------------------------------------------------------------------------
-- Copyright (c) 2019 CERN BE/CO/HT
--------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;


entity tb_gc_async_counter_diff is 
  generic (
    g_seed         : natural;
    g_bits         : integer;
    g_output_clock : string);
end entity;

architecture tb of tb_gc_async_counter_diff is

  -- Constants
  constant C_INC_CLK_PERIOD : time := 5 ns;
  constant C_DEC_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_rst_n_i   : std_logic;
  signal tb_clk_inc_i : std_logic;
  signal tb_clk_dec_i : std_logic;
  signal tb_inc_i     : std_logic := '0';
  signal tb_dec_i     : std_logic := '0';
  signal tb_counter_o : std_logic_vector(g_bits downto 0);
  signal stop         : boolean;

  -- Shared variables used in coverage
  shared variable cp_rst_n_i : covPType;
  shared variable cp_inc_i   : covPType;
  shared variable cp_dec_i   : covPType;
  shared variable cp_cnt_eq  : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_async_counter_diff
  generic map (
    g_bits         => g_bits,
    g_output_clock => g_output_clock)
  port map (
    rst_n_i   => tb_rst_n_i,
    clk_inc_i => tb_clk_inc_i,
    clk_dec_i => tb_clk_dec_i,
    inc_i     => tb_inc_i,
    dec_i     => tb_dec_i,
    counter_o => tb_counter_o);

  -- Clock inc generation
  clk_inc_process : process
  begin
    while (stop = FALSE) loop
      tb_clk_inc_i <= '1';
      wait for C_INC_CLK_PERIOD/2;
      tb_clk_inc_i <= '0';
      wait for C_INC_CLK_PERIOD/2;
    end loop;
    wait;
  end process;
    
  -- Clock dec generation
  clk_dec_process : process
  begin
    while (stop = FALSE) loop
      tb_clk_dec_i <= '1';
      wait for C_DEC_CLK_PERIOD/2;
      tb_clk_dec_i <= '0';
      wait for C_DEC_CLK_PERIOD/2;
    end loop;
    wait;
  end process;
 
  -- Reset g_output_clock domain
  tb_rst_n_i <= '0', '1' after 4*C_DEC_CLK_PERIOD;

  -- Stimulus for increment clock
  stim_inc : process
    variable ncycles 	: natural;
    variable data     : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until (rising_edge(tb_clk_inc_i) and tb_rst_n_i = '1');
      tb_inc_i <= data.randSlv(1)(1);
      wait for 10*C_INC_CLK_PERIOD;
      ncycles := ncycles + 1;
    end loop;
    report "Number of Simulation cycles (inc) = " & to_string(ncycles);
    report "Test PASS!";
    stop <= true;
    wait;
  end process;
    
  -- Stimulus for decrement clock
  stim_dec : process
    variable ncycles 	: natural;
    variable data     : RandomPType;  
  begin
    data.InitSeed(g_seed);
    while not stop loop
      wait until (rising_edge(tb_clk_dec_i) and tb_rst_n_i = '1');
      tb_dec_i <= data.randSlv(1)(1);
      wait for 10*C_DEC_CLK_PERIOD;
      ncycles := ncycles + 1;
    end loop;
    report "Number of Simulation cycles (dec) = " & to_string(ncycles);
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------
 
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset has asserted"    ,ONE_BIN);
    cp_inc_i.AddBins  ("Inc input has asserted",ONE_BIN);
    cp_dec_i.AddBins  ("Dec input has asserted",ONE_BIN);
    cp_cnt_eq.AddBins ("Counter output is zero",ONE_BIN);
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

  sample_inc_i : process
  begin
    loop
      wait until rising_edge(tb_clk_inc_i);
      cp_inc_i.ICover(to_integer(tb_inc_i = '1'));
    end loop;
  end process;

  sample_dec_i : process
  begin
    loop
      wait until rising_edge(tb_clk_dec_i);
      cp_dec_i.ICover(to_integer(tb_dec_i = '1'));
    end loop;
  end process;

  out_clk_is_inc : if (g_output_clock = "inc") generate
    sample_cnt_equal : process
    begin
      loop
        wait until rising_edge(tb_clk_inc_i) and tb_rst_n_i = '1';
        cp_cnt_eq.ICover(to_integer(unsigned(tb_counter_o) = 0));
      end loop;
    end process;
  end generate;
    
  out_clk_is_dec : if (g_output_clock = "dec") generate
    sample_cnt_equal : process
    begin
      loop
        wait until rising_edge(tb_clk_dec_i) and tb_rst_n_i = '1';
        cp_cnt_eq.ICover(to_integer(unsigned(tb_counter_o) = 0));
      end loop;
    end process;
  end generate;

  -- Report coverage 
  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_inc_i.Writebin;
    cp_dec_i.Writebin;
    cp_cnt_eq.Writebin;
  end process;

end tb;
