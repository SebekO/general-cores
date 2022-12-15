--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_edge_detect
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for simple rising edge detector.  Combinatorial.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2020
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

entity tb_gc_posedge is
  generic (
    g_seed       : natural;
    g_ASYNC_RST  : boolean;
    g_CLOCK_EDGE : string);
end entity;

architecture tb of tb_gc_posedge is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_data_i  : std_logic := '0';
  signal tb_pulse_o : std_logic;
  signal stop       : boolean;

  -- Variables used for coverage
  shared variable cp_rst_i  : covPType;
  shared variable cp_data_i : covPType;
  shared variable cp_pulse_o: covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_posedge
  generic map (
    g_ASYNC_RST  => g_ASYNC_RST,
    g_CLOCK_EDGE => g_CLOCK_EDGE)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_n_i,
    data_i  => tb_data_i,
    pulse_o => tb_pulse_o);

  -- Clock generation
  clk_proc : process
  begin
    while STOP = FALSE loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 4*C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    wait until tb_rst_n_i='1';
    while NOW < 2 ms loop
      wait until rising_edge(tb_clk_i);
      tb_data_i <= data.randSlv(1)(1);
      ncycles   := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                            Assertions                                      --
  --------------------------------------------------------------------------------

  --Assertion to check that the width of the output pulse
  --is asserted for only one clock cycle
  one_clk_width : process
  begin
    while not stop loop
      wait until rising_edge(tb_clk_i);
      if tb_pulse_o = '1' then
        wait for C_CLK_PERIOD;
        assert (tb_pulse_o = '0')
          report "output pulse remains high for more than one clock"
          severity failure;
      end if;
    end loop;
    wait;
  end process;

  -- Check that the output pulse is asserted
  -- in the rising edge of the input pulse
  check_edge : process
  begin
    while not stop loop
      wait until rising_edge(tb_data_i);
      wait for 0 ns; --wait for delta time
      assert (tb_pulse_o = '1')
        report "Positive edge didn't detect"
        severity failure;
    end loop;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                               Coverage                                     --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
  init_coverage : process
  begin
    cp_rst_i.AddBins("reset has asserted", ONE_BIN);
    cp_data_i.AddBins("Input pulse detected", ONE_BIN);
    cp_pulse_o.AddBins("Output pulse detected", ONE_BIN);
    wait;
  end process init_coverage;

  -- sample coverpoints for reset
  sample_rst_n_i : process
  begin
    loop
      wait on tb_rst_n_i;
      wait for C_CLK_PERIOD;
      cp_rst_i.ICover(to_integer(tb_rst_n_i = '1'));
    end loop;
  end process;

  -- sample coverpoints for input data
  sample_data_i : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      cp_data_i.ICover(to_integer(tb_data_i='1'));
    end if;
  end process;

  -- sample coverpoints for output pulse
  clock_edge_pos : if (g_CLOCK_EDGE="positive") generate
    sample_pulse_o : process(tb_clk_i)
    begin
      if (rising_edge(tb_clk_i)) then
        cp_pulse_o.ICover(to_integer(tb_pulse_o='1'));
      end if;
      end process;
  end generate;

  clock_edge_neg : if (g_CLOCK_EDGE="negative") generate
    sample_pulse_o : process
    begin
      loop
        wait until (falling_edge(tb_clk_i));
        cp_pulse_o.ICover(to_integer(tb_pulse_o='1'));
      end loop;
      wait;
    end process;
  end generate;

  -- Coverage report
  cover_report: process
  begin
    wait until stop;
    cp_rst_i.writebin;
    cp_data_i.writebin;
    cp_pulse_o.writebin;
  end process;

end tb;
