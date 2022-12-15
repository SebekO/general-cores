--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_multichannel_frequency_meter
--
-- author:      Konstantinos Blantos
--
-- description: Frequency meter optimized for multiple channels.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2012-2018
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

--OSVVM
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_multichannel_frequency_meter is
  generic (
    g_seed                   : natural;
    g_WITH_INTERNAL_TIMEBASE : boolean := true;
    g_CLK_SYS_FREQ           : integer;
    g_COUNTER_BITS           : integer := 32;
    g_CHANNELS               : integer := 1);
end entity;

architecture tb of tb_gc_multichannel_frequency_meter is

  -- Constants
  constant C_CLK_SYS_PERIOD  : time := 8 ns;
  constant C_CLK_IN_PERIOD   : time := 10  ns;

  -- Signals
  signal tb_clk_sys_i        : std_logic;
  signal tb_clk_in_i         : std_logic_vector(g_CHANNELS -1 downto 0) := (others=>'0');
  signal tb_rst_n_i          : std_logic;
  signal tb_pps_p1_i         : std_logic := '0';
  signal tb_channel_sel_i    : std_logic_vector(f_log2_ceil(g_CHANNELS)-1 downto 0) := (others=>'0');
  signal tb_freq_o           : std_logic_vector(g_COUNTER_BITS-1 downto 0);
  signal tb_freq_valid_o     : std_logic;
  signal stop                : boolean;
  signal s_cnt_gate          : unsigned(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_gate_pulse        : std_logic := '0';
  signal s_gate_pulse_synced : std_logic_vector(g_CHANNELS-1 downto 0) := (others=>'0');
  signal s_data_o            : std_logic_vector(g_COUNTER_BITS-1 downto 0) := (others=>'0');
  signal s_freq_valid_o      : std_logic:='0';

  -- Types
  type t_channel is record
    cnt         : unsigned(g_COUNTER_BITS-1 downto 0);
    freq        : unsigned(g_COUNTER_BITS-1 downto 0);
    freq_valid_o: std_logic;
  end record;

  type t_channel_array is array (0 to g_CHANNELS-1) of t_channel;
  signal ch        : t_channel_array;
  signal index     : integer range 0 to g_CHANNELS+1;
  signal s_ready_o : std_logic := '0';

begin

  -- Unit Under Test
  UUT : entity work.gc_multichannel_frequency_meter
  generic map (
    g_WITH_INTERNAL_TIMEBASE => g_WITH_INTERNAL_TIMEBASE,
    g_CLK_SYS_FREQ           => g_CLK_SYS_FREQ,
    g_COUNTER_BITS           => g_COUNTER_BITS,
    g_CHANNELS               => g_CHANNELS)
  port map (
    clk_sys_i     => tb_clk_sys_i,
    clk_in_i      => tb_clk_in_i,
    rst_n_i       => tb_rst_n_i,
    pps_p1_i      => tb_pps_p1_i,
    channel_sel_i => tb_channel_sel_i,
    freq_o        => tb_freq_o,
    freq_valid_o  => tb_freq_valid_o);

  -- Clock generation
  clk_sys_proc : process
  begin
    while STOP = FALSE loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process clk_sys_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 4*C_CLK_SYS_PERIOD;

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      tb_clk_in_i      <= data.randSlv(g_CHANNELS);
      wait until (rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1');
      tb_channel_sel_i <= data.randslv(0,g_CHANNELS-1,f_log2_ceil(g_CHANNELS));
      ncycles          := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process;

  -- Stimulus for pps_p1_i when time internal is FALSE
  stim_when_false : if (g_WITH_INTERNAL_TIMEBASE = FALSE) generate
    stim_false : process
      variable data : RandomPType;
    begin
      data.InitSeed(g_seed);
      while NOW < 2 ms loop
        wait until rising_edge(tb_clk_sys_i) and s_ready_o='1';
        tb_pps_p1_i <= data.randSlv(1)(1);
      end loop;
      wait;
    end process;
  end generate;

  -- Stimulus for pps_p1_i when time internal is TRUE
  stim_when_true : if (g_WITH_INTERNAL_TIMEBASE = TRUE) generate
    stim_false : process
      variable data : RandomPType;
    begin
      data.InitSeed(g_seed);
      while NOW < 2 ms loop
        wait until (rising_edge(tb_clk_sys_i) and tb_rst_n_i='1');
        tb_pps_p1_i <= data.randSlv(1)(1);
      end loop;
      wait;
    end process;
  end generate;

  --------------------------------------------------------------------------------
  --                      Self-Checking and Assertions                          --
  --------------------------------------------------------------------------------

  -- Reproduce the behavior of the internal counter
  with_internal_timebase : if (g_WITH_INTERNAL_TIMEBASE = TRUE) generate

    internal_counter : process(tb_clk_sys_i)
    begin
      if rising_edge(tb_clk_sys_i) then
        if tb_rst_n_i = '0' then
          s_cnt_gate <= (others=>'0');
          s_gate_pulse <= '0';
        else
          if s_cnt_gate = g_CLK_SYS_FREQ-1 then
            s_cnt_gate   <= (others=>'0');
            s_gate_pulse <= '1';
          else
            s_cnt_gate   <= s_cnt_gate + 1;
            s_gate_pulse <= '0';
          end if;
        end if;
      end if;
    end process;

  end generate with_internal_timebase;

  -- Reproduce the RTL behavarior to generate self-check
  gen_channels : for i in 0 to g_CHANNELS-1 generate

    internal_timebase : if (g_WITH_INTERNAL_TIMEBASE=TRUE) generate
      synced_gate : process
      begin
        while not stop loop
          wait until falling_edge(s_gate_pulse);
          wait until rising_edge(tb_clk_in_i(i));
          wait until rising_edge(tb_clk_in_i(i));
          s_gate_pulse_synced(i) <= tb_clk_in_i(i);
          wait until rising_edge(tb_clk_in_i(i));
          s_gate_pulse_synced(i) <= '0';
        end loop;
      end process;
    end generate;

    no_internal_timebase : if (g_WITH_INTERNAL_TIMEBASE=FALSE) generate

      U_Sync_Gate : gc_pulse_synchronizer
      port map (
        clk_in_i  => tb_clk_sys_i,
        clk_out_i => tb_clk_in_i(i),
        rst_n_i   => tb_rst_n_i,
        d_ready_o => s_ready_o,
        d_p_i     => tb_pps_p1_i,
        q_p_o     => s_gate_pulse_synced(i));

    end generate;

    freq_cnt : process(tb_clk_in_i(i),tb_rst_n_i)
    begin
      if tb_rst_n_i = '0' then
        ch(i).cnt          <= (others=>'0');
        ch(i).freq         <= (others=>'0');
        ch(i).freq_valid_o <= '0';
      elsif rising_edge(tb_clk_in_i(i)) then
        if s_gate_pulse_synced(i) then
          ch(i).freq_valid_o <= '1';
          ch(i).freq         <= ch(i).cnt;
          ch(i).cnt          <= (others=>'0');
        else
          ch(i).cnt <= ch(i).cnt + 1;
          ch(i).freq_valid_o <= '0';
        end if;
      end if;
    end process;
  end generate;

  index <= to_integer(unsigned(tb_channel_sel_i));

  freq_output : process(tb_clk_sys_i)
  begin
    if (rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1') then
      s_data_o <= std_logic_vector(ch(index).freq);
      s_freq_valid_o <= ch(index).freq_valid_o;
    end if;
  end process;


  -- Check for valid number of channels
  assert (g_CHANNELS > 1)
    report "Invalid number of channels" severity failure;

  -- Check if output is the expected
  check_output : process(tb_clk_sys_i)
  begin
    if (rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1') then
      assert (s_data_o = tb_freq_o)
        report "Mismatch in output" severity failure;
    end if;
  end process;

end tb;



