--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   gc_sync_ffs
--
-- description: Testbench that verifies the Synchronizer chain and edge detector.
--      All the registers in the chain are cleared at reset.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2010-2020
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

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_sync_ffs                   --
--=============================================================================

entity tb_gc_sync_ffs is
  generic (
    g_seed      : natural;
    g_SYNC_EDGE : string := "positive");
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_sync_ffs is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  --Signals
  signal tb_clk_i    : std_logic := '1';   -- clock from the destination clock domain
  signal tb_rst_n_i  : std_logic;   -- async reset
  signal tb_data_i   : std_logic := '0';   -- async input
  signal tb_synced_o : std_logic;   -- synchronized output
  signal tb_npulse_o : std_logic;   -- negative edge detect output
  signal tb_ppulse_o : std_logic;  -- positive edge detect output
  signal stop : boolean;

  -- Shared variable used for coverage
  shared variable cp_rst_i : covPType;

begin

  --Unit Under Test
  UUT : entity work.gc_sync_ffs
  generic map (
    g_SYNC_EDGE => g_SYNC_EDGE)
  port map (
    clk_i    => tb_clk_i,
    rst_n_i  => tb_rst_n_i,
    data_i   => tb_data_i,
    synced_o => tb_synced_o,
    npulse_o => tb_npulse_o,
    ppulse_o => tb_ppulse_o);

  --Clock and reset generation
  clk_process : process
  begin
    while STOP = FALSE loop
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  tb_rst_n_i <= '0', '1' after 2 * C_CLK_PERIOD;

  -- Randomized stimulus
  Stim: process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while (NOW < 1 ms)  loop
      wait until (rising_edge(tb_clk_i));
      tb_data_i <= data.randSlv(1)(1);
      nCycles   := nCycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(nCycles);
    STOP <= TRUE;
    report "Test PASS!";
    wait;
  end process Stim;

  --------------------------------------------------------------------------------
  --                           Assertions - Self Checking                       --
  --------------------------------------------------------------------------------

  -- Assertion to check if the output
  -- pulse is synchronized
  sync_output : process
  begin
    if (g_SYNC_EDGE = "positive") then
      if (tb_data_i = '1') then
        wait for 3*C_CLK_PERIOD;
        assert (tb_synced_o = '1'
          and tb_ppulse_o = '1' and tb_npulse_o='0')
        report "the output is not synchronized"
        severity failure;
      end if;
    elsif (g_SYNC_EDGE = "negative") then
      if (tb_data_i = '1') then
        wait for 3 *C_CLK_PERIOD;
        assert (tb_synced_o = '1'
          and tb_ppulse_o = '1' and tb_npulse_o='0')
        report "the output is not synchronized"
        severity failure;
      end if;
    else
      assert (g_SYNC_EDGE="positive" or g_SYNC_EDGE="negative")
      report "Wrong value for g_SYNC_EDGE"
      severity failure;
    end if;
    wait;
  end process sync_output;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
  InitCoverage: process
  begin
    cp_rst_i.AddBins("reset has asserted", ONE_BIN);
    wait;
  end process InitCoverage;

  -- Sample the coverpoints
  Sample: process
  begin
    loop
      wait on tb_rst_n_i;
      cp_rst_i.ICover (to_integer(tb_rst_n_i = '1'));
    end loop;
  end process Sample;

  -- Coverage report
  CoverReport: process
  begin
    wait until STOP;
    cp_rst_i.writebin;
  end process;


end tb;
