-------------------------------------------------------------------------------
-- Title      : Testbench for Generic input stage for asynchronous input signals
-------------------------------------------------------------------------------
-- File       : tb_gc_async_signals_input_stage.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN BE-CEM-EDL
-- Platform   : FPGA-generics
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for gc_async_signals_input_stage
--
-- A generic input stage for digital asynchronous input signals.
-- It implements a number of stages that might be generally useful/needed
-- before using such signals in a synchronous FPGA-base applications.
--
-- It includes the following input stages:
-- 1. synchronisation with clock domain with taking care for metastability
-- 2. choice of HIGH/LOW active
-- 3. degliching with a filter width set through generic
-- 4. single-clock pulse generation on edge detection
--    * rising edge if HIGH active set
--    * falling edge if LOW actvie set
-- 5. extension of pulse with width set through generic
--
-- The output provides three outputs, any of them can be used at will
--   signals_o    : synchronised and deglichted signal active LOW or HIGH,
--                  depending on conifg
--   signals_p_o  : single-clock pulse on rising/faling edge of the synchronised
--                  and degliched signal
--   signals_pN_o : the single-clock pulse extended
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2016 CERN/TE-MS-MM
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
-- Revisions  :
-- Date        Version  Author          Description
-- 2021-11-26  1.0      kblantos        created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_async_signals_input_stage is
  generic (
    g_seed                 : natural;
    g_signal_num           : integer;
    g_extended_pulse_width : integer;
    g_dglitch_filter_len   : integer);
end entity;

architecture tb of tb_gc_async_signals_input_stage is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i           : std_logic;
  signal tb_rst_n_i         : std_logic;
  signal tb_signals_a_i     : std_logic_vector(g_signal_num-1 downto 0) :=(others=>'0');
  signal tb_config_active_i : std_logic_vector(g_signal_num-1 downto 0) :=(others=>'0');
  signal tb_signals_o       : std_logic_vector(g_signal_num-1 downto 0);
  signal tb_signals_p1_o    : std_logic_vector(g_signal_num-1 downto 0);
  signal tb_signals_pN_o    : std_logic_vector(g_signal_num-1 downto 0);
  signal stop               : boolean;

begin

  -- Unit Under Test
  UUT : entity work.gc_async_signals_input_stage
  generic map (
    g_signal_num           => g_signal_num,
    g_extended_pulse_width => g_extended_pulse_width,
    g_dglitch_filter_len   => g_dglitch_filter_len)       
  port map (
    clk_i           => tb_clk_i,
    rst_n_i         => tb_rst_n_i,
    signals_a_i     => tb_signals_a_i,
    config_active_i => tb_config_active_i,
    signals_o       => tb_signals_o, 
    signals_p1_o    => tb_signals_p1_o,
    signals_pN_o    => tb_signals_pN_o);
    
  -- Clock and reset generation
  clk_i_process : process
  begin
    while (not stop) loop
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
    while (NOW < 1 ms) loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_signals_a_i     <= data.randSlv(g_signal_num);
      tb_config_active_i <= data.randSlv(g_signal_num);
      ncycles := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------------
   
  -- At least one signal to be synchronized
  assert (g_signal_num > 0)
    report "Invalid value of input signals" severity failure;
    
  -- Zero or more than one is the valid value of extended pulse width
  -- (due to dependency of gc_extend_pulse)
  assert (g_extended_pulse_width = 0 or g_extended_pulse_width > 1)
    report "Invalid value of extended pulse width value" severity failure;

  -- Checking that signals_p1_o is '1' on rising or falling edge (depending the conf.)
  gen_signals : for i in 0 to g_signal_num-1 generate

    check_signals_p1 : process 
    begin
      while not stop loop
        wait until rising_edge(tb_clk_i) and tb_rst_n_i = '1';
        wait until rising_edge(tb_signals_o(i));
        wait for 2*C_CLK_PERIOD; 
        assert (tb_signals_p1_o(i) = '1')
        report "Wrong value for single-clock output" severity failure;
      end loop;
    end process;     

    -- Checking that signals_pn is '1' on rising or falling edge (depending the conf.)
    gen_with_pulse_extender : if g_extended_pulse_width>1 generate
      check_signals_pn : process
      begin
        while not stop loop
          wait until (tb_signals_o(i) = '1');
          wait for g_extended_pulse_width*C_CLK_PERIOD;
          assert (tb_signals_pn_o(i) = '1')
          report "Wrong value for multi-clock output" severity failure;
        end loop;
      end process;
    end generate gen_with_pulse_extender;
    
      -- Value of signals_p1 and signals_pn is the same, except that pn is extended
      check_same_value : process
      begin
        while not stop loop
          wait until rising_edge(tb_clk_i) and tb_rst_n_i = '1';
          wait until rising_edge(tb_signals_o(i));
          wait for 2*C_CLK_PERIOD;
          assert (tb_signals_p1_o(i) = tb_signals_pn_o(i))
          report "different output pulses" severity failure;
        end loop;
      end process;

  end generate gen_signals;
   
end tb;
