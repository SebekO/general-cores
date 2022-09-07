-------------------------------------------------------------------------------
-- Title      : Testbench for Pulse width extender
-- Project    : General Cores library
-------------------------------------------------------------------------------
-- File       : tb_gc_extend_pulse.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN
-- Created    : 2021-11-25
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description:
-- Testbench for Synchronous pulse extender. Generates a pulse of programmable 
-- width upon detection of a rising edge in the input. OSVVM used for coverage
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009-2011 CERN
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
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_extend_pulse is
  generic (
    g_seed  : natural;
    g_width : natural := 1000);
end entity;

architecture tb of tb_gc_extend_pulse is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i      : std_logic;
  signal tb_rst_n_i    : std_logic;
  signal tb_pulse_i    : std_logic;
  signal tb_extended_o : std_logic;
  signal stop          : boolean;
  signal s_cnt         : unsigned(f_log2_ceil(g_width)-1 downto 0);

  -- Shared variables, used for coverage  
  shared variable cp_rst_n_i      : covPType;
  shared variable cp_pulse_detect : covPType;
  shared variable cp_ext_pulse_o  : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_extend_pulse
  generic map (
    g_width => g_width)
  port map (
    clk_i      => tb_clk_i,
    rst_n_i    => tb_rst_n_i,
    pulse_i    => tb_pulse_i,
    extended_o => tb_extended_o);

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
    while NOW < 2.5 ms loop
      wait until rising_edge(tb_clk_i) and tb_rst_n_i = '1';
      tb_pulse_i <= data.randSlv(1)(1);
      ncycles    := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                               Assertions                                   --
  --------------------------------------------------------------------------------

  -- Checks that the length of the output pulse is not bigger than
  -- the specified length   
  check_extended_o : process(tb_clk_i)
  begin
    if tb_rst_n_i = '0' then
      s_cnt <= (others=>'0');
    elsif (rising_edge(tb_clk_i)) then
      if (tb_pulse_i = '0' and tb_extended_o = '1') then
        s_cnt <= s_cnt + 1;
        assert (s_cnt <= g_width)
          report "Output pulse high for longer period" severity failure;
        if s_cnt > g_width then
          s_cnt <= (others=>'0');
        end if;
      else
        s_cnt <= (others=>'0');
      end if;
    end if;
  end process;

  -- Output extended pulse is rising when input pulse is asserted
  both_high : process(tb_clk_i)
  begin
    if (rising_edge(tb_clk_i) and tb_rst_n_i = '1') then
      if (tb_pulse_i = '1') then
        assert (tb_extended_o = '1')
          report "Output pulse not high when input pulse is high" severity failure;
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
    cp_pulse_detect.AddBins("output pulse high when input high", ONE_BIN);
    cp_ext_pulse_o.AddBins("output pulse de-asserted when max width",ONE_BIN);
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

  sample_pulse_detect : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_pulse_detect.ICover(to_integer((tb_pulse_i = '1') 
                                  and tb_extended_o = '1'));
      end loop;
  end process;

  sample_out_pulse : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      if s_cnt = g_width-1 then
        cp_ext_pulse_o.ICover(to_integer(tb_extended_o = '0'));
      end if;
    end loop;
  end process;

  -- Coverage report
  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_pulse_detect.Writebin;
    cp_ext_pulse_o.Writebin;
  end process;

end tb;
