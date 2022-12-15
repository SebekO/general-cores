--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_sync_word_wr
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
-- description: Synchronizer for writing a word with an ack.
--
--   Used to transfer a word from the input clock domain to the output clock
--   domain.  User provides the data and a pulse write signal to transfer the
--   data.  When the data are transfered, a write pulse is generated on the
--   output side along with the data, and an acknowledge is generated on the
--   input side.  Once the user requests a transfer, no new data should be
--   requested for a transfer until the ack is received. A busy flag is also
--   available for this purpose (user should not push new data if busy).
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
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

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_sync_word_wr               --
--=============================================================================

entity tb_gc_sync_word_wr is
  generic (
    g_seed    : natural;
    -- Automatically write next word when not busy.
    g_AUTO_WR : boolean  := TRUE; --FALSE;
    g_WIDTH   : positive := 8);
end;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_sync_word_wr is

  -- Constants
  constant C_CLK_IN_PERIOD  : time := 10 ns;
  constant C_CLK_OUT_PERIOD : time := 7  ns;

  -- Signals
  signal tb_din           : std_logic_vector(g_WIDTH-1 downto 0) := (others=>'0');
  signal tb_dout          : std_logic_vector(g_WIDTH-1 downto 0);
  signal tb_clki, tb_clko : std_logic := '0';
  signal tb_rsti, tb_rsto : std_logic;
  signal tb_wri, tb_wro   : std_logic;
  signal tb_ack, tb_busy  : std_logic;
  signal s_data_o         : std_logic_vector(g_WIDTH-1 downto 0) := (others=>'0');
  signal stop             : boolean;

  -- Shared variables used for coverage
  shared variable cp_rst_in_i  : covPType;
  shared variable cp_rst_out_i : covPType;

begin

  --Unit Under Test
  UUT : entity work.gc_sync_word_wr
    generic map (
      g_AUTO_WR => g_AUTO_WR,
      g_WIDTH   => g_WIDTH)
    port map (
      clk_in_i    => tb_clki,
      rst_in_n_i  => tb_rsti,
      clk_out_i   => tb_clko,
      rst_out_n_i => tb_rsto,
      data_i      => tb_din,
      wr_i        => tb_wri,
      busy_o      => tb_busy,
      ack_o       => tb_ack,
      data_o      => tb_dout,
      wr_o        => tb_wro);

  -- Input clock/reset
  clk_in : process
  begin
    while not stop loop
      tb_clki <= '0';
      wait for C_CLK_IN_PERIOD/2;
      tb_clki <= '1';
      wait for C_CLK_OUT_PERIOD/2;
    end loop;
    wait;
  end process clk_in;

  tb_rsti <= '0', '1' after 3 * C_CLK_IN_PERIOD;

  -- Output clock/reset
  clk_out : process
  begin
    while not stop loop
      tb_clko <= '0';
      wait for C_CLK_OUT_PERIOD/2;
      tb_clko <= '1';
      wait for C_CLK_OUT_PERIOD/2;
    end loop;
    wait;
  end process clk_out;

  tb_rsto <= '0', '1' after 4 * C_CLK_OUT_PERIOD;

  -- Randomized stimulus
  stim : process
    variable data : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    tb_wri <= '0';
    wait until tb_rsti = '1';
    while (NOW < 1 ms) loop
      wait until (rising_edge(tb_clki) and tb_busy='0');
      tb_din  <= data.randSlv(g_WIDTH);
      tb_wri  <= data.randSlv(1)(1);
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                           Assertions - Self Checking                       --
  --------------------------------------------------------------------------------

  -- Assertion to verify the behavior of ACK signal
  data_o_check : process
  begin
    if rising_edge(tb_clki) then
      assert (tb_ack /= tb_wro)
        report "ACK and write enable equal" severity failure;
      assert (tb_ack /= tb_busy)
        report "ACK while still busy" severity failure;
    end if;
    wait;
  end process data_o_check;

  --Self-Checking: Checks that the output data is the
  --same as the input data
  not_auto_wr : if (g_AUTO_WR = FALSE) generate
    wr_side : process(tb_clki)
    begin
      if rising_edge(tb_clki) then
        if (tb_wri='1' and tb_busy = '0') then
          s_data_o <= tb_din;
        end if;
      end if;
    end process;
  end generate;

  auto_wr : if (g_AUTO_WR = TRUE) generate
    wr_side : process (tb_clki)
    begin
      if rising_edge(tb_clki) then
        if (tb_busy= '0') then
          s_data_o <= tb_din;
        end if;
      end if;
    end process;
  end generate;

  rd_side_self_check : process(tb_clko)
  begin
    if rising_edge(tb_clko) then
      if (tb_wro = '1') then
        assert (s_data_o = tb_dout)
          report "data mismatch" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------

  --sets up coverpoint bins
  InitCoverage: process
  begin
    cp_rst_in_i.AddBins("input reset has been asserted", ONE_BIN);
    cp_rst_out_i.AddBins("output reset has been asserted", ONE_BIN);
    wait;
  end process InitCoverage;

  -- Sample the simple coverpoints
  Sample: process
  begin
    loop
      wait on tb_rsti;
      wait on tb_rsto;
      wait for C_CLK_IN_PERIOD;
      cp_rst_in_i.ICover (to_integer(tb_rsti = '1'));
      cp_rst_out_i.ICover (to_integer(tb_rsto = '1'));
    end loop;
  end process Sample;

  -- Coverage report
  CoverReport: process
  begin
    wait until STOP;
    cp_rst_in_i.writebin;
    cp_rst_out_i.writebin;
  end process;

end tb;





