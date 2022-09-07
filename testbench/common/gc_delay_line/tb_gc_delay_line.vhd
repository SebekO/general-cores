-------------------------------------------------------------------------------
-- Title      : Testbench for Parametrized delay block
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_gc_delay_line.vhd
-- Company    : CERN (BE-CEM-EDL)
-- Author     : Konstantinos Blantos
-- Platform   : FPGA-generics
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Copyright (c) 2011-2017 CERN
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
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-------------------------------------------------------------------------------

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;

--OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_delay_line                 --
--=============================================================================

entity tb_gc_delay_line is
  generic (
    g_seed  : natural;
    g_delay : natural := 2;
    g_width : natural := 8);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_delay_line is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_d_i     : std_logic_vector(g_width-1 downto 0);
  signal tb_q_o     : std_logic_vector(g_width-1 downto 0);
  signal tb_ready_o : std_logic;

  signal stop       : boolean;
  signal s_cnt      : unsigned(g_delay-1 downto 0) := (others=>'0');

  -- array used for self-checking 
  type t_dly_array is array (0 to g_delay) of std_logic_vector(g_width-1 downto 0);
  signal s_dly_arr : t_dly_array;

begin

  -- Unit Under Test
  UUT : entity work.gc_delay_line
  generic map (
    g_delay => g_delay,
    g_width => g_width)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_n_i,
    d_i     => tb_d_i,
    q_o     => tb_q_o,
    ready_o => tb_ready_o);

  -- Clock and reset generation
  clk_i_process : process
  begin
    while stop = FALSE loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  --Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 1 ms loop
      wait until rising_edge(tb_clk_i) and tb_rst_n_i = '1';
      tb_d_i  <= data.randSlv(g_width);
      ncycles := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  ------------------------------------------------------------------------------
  --                        Assertions - Self Checking                        --
  ------------------------------------------------------------------------------

  -- Delay should be higher than 1
  assert (g_delay > 1)
  report "Wrong value for Delay" severity failure;

  -- Fill in the array with random input data 
  delay_array : process(tb_clk_i)
  begin
    if (tb_rst_n_i = '0') then
      for_rst : for i in 0 to g_delay loop
        s_dly_arr(i) <= (others=>'0');
      end loop;
    elsif (rising_edge(tb_clk_i) and tb_ready_o = '1') then
      s_dly_arr(0) <= tb_d_i;
      for_clk : for i in 0 to g_delay-1 loop
        s_dly_arr(i+1) <= s_dly_arr(i);
      end loop;
    end if;
  end process;

  -- Self-checking process  
  self_check : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) and tb_rst_n_i = '1' then
      if tb_ready_o = '1' then
        if s_cnt >= 0 and s_cnt < g_delay then
          s_cnt <= s_cnt + 1;
        elsif (s_cnt = g_delay) then
          s_cnt <= (others=>'0');
          assert (s_dly_arr(g_delay-1)= tb_q_o)
            report "Data mismatch" severity error;
        end if;
      end if;
    end if;
  end process;

end tb;



