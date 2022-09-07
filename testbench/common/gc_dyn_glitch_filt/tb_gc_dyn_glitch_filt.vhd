--==============================================================================
-- CERN (BE-CEM-EDL)
-- Testbench for Glitch filter with dynamically selectable length
--==============================================================================
--
-- author: Konstantinos Blantos (Konstantinos.Blantos@cern.ch)
--
-- date of creation: 2021-11-24
--
-- version: 1.0
--
-- description:
--    Testbench for gc_glitch_filt. Glitch filter consisting of a set of 
--    chained flip-flops followed by a comparator. The comparator toggles 
--    to '1' when all FFs in the chain are '1' and respectively to '0' when 
--    all the FFS in the chain are '0'. Latency = len_i + 1.
--
-- references:
--    Based on gc_glitch_filter.vhd
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

entity tb_gc_dyn_glitch_filt is 
  generic (
    g_seed      : natural;
    g_len_width : natural := 4);
end entity;

architecture tb of tb_gc_dyn_glitch_filt is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_len_i   : std_logic_vector(g_len_width-1 downto 0) := (others=>'0');
  signal tb_dat_i   : std_logic := '0';
  -- latecy : g_len+1 clk_i cycles
  signal tb_dat_o   : std_logic;
  signal stop       : boolean;
  signal s_cnt      : unsigned(g_len_width-1 downto 0) := (others=>'0');

  -- Shared variables, used for coverage
  shared variable cp_rst_n_i           : covPType;
  shared variable cp_high_pulse_detect : covPType;
  shared variable cp_low_pulse_detect  : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_dyn_glitch_filt
  generic map (
    g_len_width => g_len_width)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_n_i,
    len_i   => tb_len_i,
    dat_i   => tb_dat_i,
    dat_o   => tb_dat_o);

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
    while NOW < 4 ms loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_dat_i <= data.randSlv(1)(1);
      tb_len_i <= data.randSlv(g_len_width);
      wait for 4*C_CLK_PERIOD;    
      ncycles  := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                           Assertions                                       --
  --------------------------------------------------------------------------------

  -- Check that the number of bits of the glitch filter length is more than zero
  len_filter : assert (g_len_width > 0)
    report "Length of glitch filter is invalid" severity failure;

  -- If dat_i is HIGH, the output is HIGH after len_i clk cycles
  -- Same goes for dat_i is LOW
  check_output : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_cnt <= unsigned(tb_len_i) srl 1;  
      else
        if rising_edge(tb_dat_i) then 
          if s_cnt = unsigned(tb_len_i) + 1 then
            s_cnt <= (others=>'0');
            assert (tb_dat_o = '1')
              report "Data not HIGH after specified length of clocks" 
              severity failure;
          else
            s_cnt <= s_cnt + 1;
          end if;
        elsif falling_edge(tb_dat_i) then 
          if s_cnt = unsigned(tb_len_i) then
            assert (tb_dat_o = '0')
              report "Data not LOW after specified length of clocks"
              severity failure;
          else
            s_cnt <= s_cnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                              Coverage                                      --
  --------------------------------------------------------------------------------
    
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset has asserted", ONE_BIN);
    cp_high_pulse_detect.AddBins("output pulse high when input high", ONE_BIN);
    cp_low_pulse_detect.AddBins("output pulse low when input low", ONE_BIN);
    wait;
  end process;
    
  sample_rst_cov : process
  begin
    loop
      wait on tb_rst_n_i;
      wait for C_CLK_PERIOD;
      --sample the coverpoints
      cp_rst_n_i.ICover(to_integer(tb_rst_n_i = '1'));
    end loop;
  end process;

  sample_high_pulse_detect : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_high_pulse_detect.ICover(to_integer((tb_dat_i = '1') 
                                          and tb_dat_o = '1'));
    end loop;
  end process;

  sample_low_pulse_detect : process
  begin
    loop
      wait  until rising_edge(tb_clk_i);
      cp_low_pulse_detect.ICover(to_integer((tb_dat_i = '0')
                                         and tb_dat_o = '0'));
    end loop;
  end process;

  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_high_pulse_detect.Writebin;
    cp_low_pulse_detect.Writebin;
  end process;

end tb;

