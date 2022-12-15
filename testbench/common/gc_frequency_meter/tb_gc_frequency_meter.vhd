--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_frequency_meter
--
-- description: Testbench for Frequency meter with internal or external timebase
--
--------------------------------------------------------------------------------
-- Copyright CERN 2012-2019
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

--  Principle of operation:
--
--  This block counts the number of pulses on CLK_IN_I during a period.
--  At the end of the period, the value is saved and the counter reset.
--  The saved value is available on FREQ_O, which is synchronized with
--  CLK_SYS_I if G_SYNC_OUT is True.
--  The width of the counter is defined by G_COUNTER_BITS.
--
--  - If g_WITH_INTERNAL_TIMEBASE is True:
--    The period is defined by an internal counter that generates a pulse
--    every G_CLK_SYS_FREQ CLK_SYS_I ticks.
--
--  - If g_WITH_INTERNAL_TIMEBASE is False:
--    The period is defined by PPS_P1_I
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_frequency_meter is
  generic (
    g_seed                   : natural;
    g_WITH_INTERNAL_TIMEBASE : boolean := FALSE;
    g_CLK_SYS_FREQ           : integer := 10;
    g_SYNC_OUT               : boolean := FALSE;
    g_COUNTER_BITS           : integer := 8);
end entity;

architecture tb of tb_gc_frequency_meter is

  -- Constants
  constant C_CLK_SYS_PERIOD : time := 8 ns;
  constant C_CLK_IN_PERIOD  : time := 10  ns;

  -- Signals
  signal tb_clk_sys_i    : std_logic;
  signal tb_clk_in_i     : std_logic;
  signal tb_rst_n_i      : std_logic;
  signal tb_pps_p1_i     : std_logic;
  signal tb_freq_o       : std_logic_vector(g_COUNTER_BITS-1 downto 0);
  signal tb_freq_valid_o : std_logic;
  signal stop            : boolean := FALSE;
  signal s_cnt_gate      : unsigned(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_gate_pulse    : std_logic := '0';
  signal s_cnt_freq      : unsigned(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_data_o        : std_logic_vector(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_freq          : std_logic_vector(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_gate_pulse_synced : std_logic := '0';

begin

  -- Unit Under Test
  UUT : entity work.gc_frequency_meter
  generic map (
    g_WITH_INTERNAL_TIMEBASE => g_WITH_INTERNAL_TIMEBASE,
    g_CLK_SYS_FREQ           => g_CLK_SYS_FREQ,
    g_SYNC_OUT               => g_SYNC_OUT,
    g_COUNTER_BITS           => g_COUNTER_BITS)
  port map (
    clk_sys_i    => tb_clk_sys_i,
    clk_in_i     => tb_clk_in_i,
    rst_n_i      => tb_rst_n_i,
    pps_p1_i     => tb_pps_p1_i,
    freq_o       => tb_freq_o,
    freq_valid_o => tb_freq_valid_o);

  -- Clocks generation
  clk_sys_proc : process
  begin
    while not stop loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process clk_sys_proc;

  clk_in_proc : process
  begin
    while not stop loop
      tb_clk_in_i <= '1';
      wait for C_CLK_IN_PERIOD/2;
      tb_clk_in_i <= '0';
      wait for C_CLK_IN_PERIOD/2;
    end loop;
    wait;
  end process clk_in_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 4*C_CLK_SYS_PERIOD;

  -- Stimulus if g_with_internal_timebase = TRUE
  stim_with_internal_timebase : if (g_with_internal_timebase = TRUE) generate
    stim : process
        variable ncycles : natural;
        variable data    : RandomPType;
    begin
      data.InitSeed(g_seed);
      report "[STARTING] with seed = " & to_string(g_seed);
      while NOW < 2 ms loop
        wait until rising_edge(tb_clk_sys_i);
        tb_pps_p1_i <= data.randSlv(1)(1);
        ncycles := ncycles + 1;
      end loop;
      report "Number of simulation cycles = " & to_string(ncycles);
      stop <= TRUE;
      report "Test PASS!";
      wait;
    end process;
  end generate;

  -- Stimulus if g_with_internal_timebase = TRUE
  stim_without_internal_timebase : if (g_with_internal_timebase = FALSE) generate
    stim : process
      variable ncycles : natural;
      variable data    : RandomPType;
    begin
      data.InitSeed(g_seed);
      report "[STARTING] with seed = " & to_string(g_seed);
      while NOW < 2 ms loop
        wait until (rising_edge(tb_clk_sys_i) and tb_freq_valid_o = '1');
        tb_pps_p1_i <= data.randSlv(1)(1);
        ncycles := ncycles + 1;
      end loop;
      report "Number of simulation cycles = " & to_string(ncycles);
      stop <= TRUE;
      report "Test PASS!";
      wait;
    end process;
  end generate;

  --------------------------------------------------------------------------------
  -- Self-Checking and Assertions
  --------------------------------------------------------------------------------

  -- Reproduce the behavior of the internal counter
  with_internal_timebase : if (g_WITH_INTERNAL_TIMEBASE = TRUE) generate

    internal_counter : process(tb_clk_sys_i)
    begin
      if rising_edge(tb_clk_sys_i) then
        if s_cnt_gate = g_CLK_SYS_FREQ-1 then
          s_cnt_gate   <= (others=>'0');
          s_gate_pulse <= '1';
        else
          s_cnt_gate   <= s_cnt_gate + 1;
          s_gate_pulse <= '0';
        end if;
      end if;
    end process;

    -- generate s_gate_pulse_synced
    gate_pulse_sync : process
    begin
      while not stop loop
        wait until falling_edge(s_gate_pulse);
        wait until rising_edge(tb_clk_in_i);
        wait for C_CLK_IN_PERIOD;
        s_gate_pulse_synced <= '1';
        wait for C_CLK_IN_PERIOD;
        s_gate_pulse_synced <= '0';
      end loop;
    end process;

  end generate with_internal_timebase;

  -- Reproduce the behavior when no internal timebase activated
  no_internal_timebase : if (g_WITH_INTERNAL_TIMEBASE = FALSE) generate

    no_internal_counter : process
    begin
      while not stop loop
        wait until falling_edge(tb_freq_valid_o);
        wait until rising_edge(tb_clk_in_i);
        wait for C_CLK_IN_PERIOD;
        s_gate_pulse_synced <= '1';
        wait for C_CLK_IN_PERIOD;
        s_gate_pulse_synced <= '0';
      end loop;
      wait;
    end process;

  end generate;

  -- Reproduce the output and store it in a register
  output_data : process(tb_clk_in_i)
  begin
    if rising_edge(tb_clk_in_i) then
      if falling_edge(s_gate_pulse_synced) then
        s_data_o   <= std_logic_vector(s_cnt_freq);
        s_cnt_freq <= (others=>'0');
      else
        s_cnt_freq <= s_cnt_freq + 1;
      end if;
    end if;
  end process;

  sync_out : if (g_SYNC_OUT = FALSE) generate
    check_unsync_out_data : process
    begin
      while not stop loop
        wait until tb_freq_valid_o = '1';
        wait until rising_edge(tb_clk_in_i);
        assert (s_data_o = tb_freq_o)
          report "Data mismatch" severity failure;
      end loop;
    end process;
  end generate;

  -- output synced with clk_sys_i. Put in s_freq register the value
  -- that will be presented in the output and compare it with s_data_o
  no_sync_out : if (g_SYNC_OUT = TRUE) generate
    check_sync_out_data : process
    begin
      while not stop loop
        wait until falling_edge(s_gate_pulse_synced);
        s_freq <= std_logic_vector(s_cnt_freq);
        wait until rising_edge(tb_clk_sys_i);
        assert (s_data_o = s_freq)
          report "Data mismatch" severity failure;
      end loop;
    end process;
  end generate;

end tb;
