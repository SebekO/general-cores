--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   tb_gc_pulse_synchronizer2
--
-- description: Full feedback pulse synchronizer (works independently of the
-- input/output clock domain frequency ratio) with separate resets per domain
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

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;


entity tb_gc_pulse_synchronizer2 is
  generic (
    g_seed : natural);
end entity;

architecture tb of tb_gc_pulse_synchronizer2 is

  -- Constants
  constant C_CLK_IN_PERIOD  : time := 5 ns;
  constant C_CLK_OUT_PERIOD : time := 10 ns;

  -- signals
  signal tb_clk_in_i    : std_logic;
  signal tb_rst_in_n_i  : std_logic;
  signal tb_clk_out_i   : std_logic;
  signal tb_rst_out_n_i : std_logic;
  signal tb_d_ready_o   : std_logic;
  signal tb_d_ack_p_o   : std_logic;
  signal tb_d_p_i       : std_logic := '0';
  signal tb_q_p_o       : std_logic;
  signal stop : boolean := FALSE;

  -- Shared variables used for coverage
  shared variable cp_rst_in_i  : covPType;
  shared variable cp_rst_out_i : covPType;
  shared variable cp_data_i    : covPType;
  shared variable cp_data_o    : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_pulse_synchronizer2
  port map (
    clk_in_i    => tb_clk_in_i,
    rst_in_n_i  => tb_rst_in_n_i,
    clk_out_i   => tb_clk_out_i,
    rst_out_n_i => tb_rst_out_n_i,
    d_ready_o   => tb_d_ready_o,
    d_ack_p_o   => tb_d_ack_p_o,
    d_p_i       => tb_d_p_i,
    q_p_o       => tb_q_p_o);

  -- Clocks generation
  clk_in_gen : process
  begin
    while not stop loop
      tb_clk_in_i <= '1';
      wait for C_CLK_IN_PERIOD/2;
      tb_clk_in_i <= '0';
      wait for C_CLK_IN_PERIOD/2;
    end loop;
    wait;
  end process;

  clk_out_gen : process
  begin
    while not stop loop
      tb_clk_out_i <= '1';
      wait for C_CLK_OUT_PERIOD/2;
      tb_clk_out_i <= '0';
      wait for C_CLK_OUT_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Resets generation
  tb_rst_in_n_i  <= '0', '1' after 2*C_CLK_IN_PERIOD;
  tb_rst_out_n_i <= '0', '1' after 2*C_CLK_OUT_PERIOD;


  -- Stimulus
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until (rising_edge(tb_clk_in_i) and tb_d_ready_o = '1');
      tb_d_p_i <= data.randSlv(1)(1);
      ncycles  := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------

  -- Self-Checking : after the de-assertion of ready_o, after one clock cycle
  -- (due to g_sync module), we want the output to be like the input pulse
  -- but last for one clock
  valid_out_data : process
  begin
    wait until (tb_rst_in_n_i = '1' and tb_rst_out_n_i = '1');
    while not stop loop
      wait until falling_edge(tb_d_ready_o);
      wait until rising_edge(tb_clk_out_i);
      wait for 2*C_CLK_OUT_PERIOD;
      assert (tb_q_p_o = '1')
        report "output is wrong" severity failure;
    end loop;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                                  Coverage                                  --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
  init_coverage : process
  begin
    cp_rst_in_i.AddBins("reset in has been asserted", ONE_BIN);
    cp_rst_out_i.AddBins("reset out has been asserted",ONE_BIN);
    cp_data_i.AddBins("new HIGH data arrives",ONE_BIN);
    cp_data_o.AddBins("output pulse for HIGH input",ONE_BIN);
    wait;
  end process init_coverage;

  -- Sample the coverpoints
  sample_rst_i : process
  begin
    loop
      wait on tb_rst_in_n_i;
      wait for C_CLK_IN_PERIOD;
      cp_rst_in_i.ICover(to_integer(tb_rst_in_n_i = '1'));
    end loop;
  end process sample_rst_i;

  sample_rst_out : process
  begin
    loop
      wait on tb_rst_out_n_i;
      wait for C_CLK_OUT_PERIOD;
      cp_rst_out_i.ICover(to_integer(tb_rst_out_n_i = '1'));
    end loop;
  end process sample_rst_out;

  sample_data_i : process
  begin
    loop
      wait until (rising_edge(tb_clk_in_i));
      wait until (rising_edge(tb_d_p_i));
      cp_data_i.ICover(to_integer(tb_d_p_i = '1'));
    end loop;
  end process;

  sample_data_o : process
  begin
    loop
      wait until (falling_edge(tb_d_ready_o));
      wait until (rising_edge(tb_q_p_o));
      cp_data_o.ICover(to_integer(tb_q_p_o='1'));
    end loop;
  end process;

  -- coverage reports
  cover_report: process
  begin
    wait until stop;
    cp_rst_out_i.writebin;
    cp_rst_in_i.writebin;
    cp_data_i.writebin;
    cp_data_o.writebin;
  end process;



end tb;

