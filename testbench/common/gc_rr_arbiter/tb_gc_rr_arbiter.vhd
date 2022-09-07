-------------------------------------------------------------------------------
-- Title      : Testbench for Round-robin arbiter
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_gc_rr_arbiter.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Platform   : FPGA-generics
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Copyright (c) 2012 CERN
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_rr_arbiter is
  generic (
    g_seed : natural;
    g_size : integer := 3);
end entity;

architecture tb of tb_gc_rr_arbiter is

  -- constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- signals
  signal tb_clk_i        : std_logic;
  signal tb_rst_n_i      : std_logic;
  signal tb_req_i        : std_logic_vector(g_size-1 downto 0) := (others=>'0');
  signal tb_grant_o      : std_logic_vector(g_size-1 downto 0);
  signal tb_grant_comb_o : std_logic_vector(g_size-1 downto 0);
  signal stop            : boolean;
  signal s_grant_del     : std_logic_vector(g_size-1 downto 0) := (others=>'0');
  signal s_data_o        : std_logic_vector(g_size-1 downto 0) := (others=>'0');
  signal s_cnt           : unsigned(1 downto 0);

begin

  -- Unit Under Test
  UUT : entity work.gc_rr_arbiter
  generic map (
    g_size => g_size)
  port map (
    clk_i        => tb_clk_i,
    rst_n_i      => tb_rst_n_i,
    req_i        => tb_req_i, 
    grant_o      => tb_grant_o, 
    grant_comb_o => tb_grant_comb_o);

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
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_req_i <= data.randSlv(g_size);
      wait for g_size*C_CLK_PERIOD;
      ncycles  := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process;

  -- grant_comb_o is the same as gtant_o with 1 clock delay
  compare_grants : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '1' then
        s_grant_del <= tb_grant_comb_o; 
        assert (tb_grant_o = s_grant_del)
          report "grant_o and grant_comb_o not the same after 1 clock"
          severity failure;
      end if;
    end if;
  end process;

  process
  begin
    while not stop loop
      wait until tb_rst_n_i = '1';
      assert ((to_integer(unsigned(tb_grant_comb_o))) mod 2 = 0
                    or unsigned(tb_grant_comb_o) = 0
                    or unsigned(tb_grant_comb_o) = 1)
        report "wrong grant" severity failure;
    end loop;
    wait;
  end process;

end tb;
