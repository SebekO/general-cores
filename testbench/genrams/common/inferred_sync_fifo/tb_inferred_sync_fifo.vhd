--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_inferred_sync_fifo
--
-- authos:      Konstantinos Blantos
--
-- description: Testbench for a parametrizable synchronous FIFO (Generic version).
--
--------------------------------------------------------------------------------
-- Copyright CERN 2011-2020
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

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.genram_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_inferred_sync_fifo
--=================================================================================================

entity tb_inferred_sync_fifo is
  generic (
    g_seed                   : natural;
    g_data_width             : natural;
    g_size                   : natural;
    g_show_ahead             : boolean;
    g_show_ahead_legacy_mode : boolean;
    g_with_empty             : boolean := true;
    g_with_full              : boolean := true;
    g_with_almost_empty      : boolean := false;
    g_with_almost_full       : boolean := false;
    g_with_count             : boolean := false;
    g_almost_empty_threshold : integer := 1;
    g_almost_full_threshold  : integer := 31;
    g_register_flag_outputs  : boolean := true);
end entity;

--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_inferred_sync_fifo is

  -- constants
  constant c_pointer_width : integer := f_log2_size(g_size);
  constant C_CLK_PERIOD    : time := 10 ns;

  -- signals
  signal tb_rst_n_i        : std_logic := '1';
  signal tb_clk_i          : std_logic;
  signal tb_d_i            : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
  signal tb_we_i           : std_logic := '0';
  signal tb_q_o            : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
  signal tb_rd_i           : std_logic := '0';
  signal tb_empty_o        : std_logic;
  signal tb_full_o         : std_logic;
  signal tb_almost_empty_o : std_logic;
  signal tb_almost_full_o  : std_logic;
  signal tb_count_o        : std_logic_vector(f_log2_size(g_size)-1 downto 0);

  signal stop  : boolean;
  signal tb_wr : std_logic := '0';
  signal tb_rd : std_logic := '0';

  -- signals for coverage
  shared variable cp_write_while_empty     : covPType;
  shared variable cp_write_while_alm_empty : covPType;
  shared variable cp_write_while_alm_full  : covPType;
  shared variable cp_read_while_full       : covPType;
  shared variable cp_read_while_alm_empty  : covPType;
  shared variable cp_read_while_alm_full   : covPType;

  -- 2D array is for self-checking purpose
  type t_array is array (0 to g_size)
          of std_logic_vector(g_data_width-1 downto 0);

  signal s_arr    : t_array := (others=>(others=>'0'));
  signal s_wr_ptr : natural := 0;
  signal s_rd_ptr : natural := 0;

begin

  -- Unit Under Test
  UUT : entity work.inferred_sync_fifo
  generic map (
    g_data_width             => g_data_width,
    g_size                   => g_size,
    g_show_ahead             => g_show_ahead,
    g_show_ahead_legacy_mode => g_show_ahead_legacy_mode,
    g_with_empty             => g_with_empty,
    g_with_full              => g_with_full,
    g_with_almost_empty      => g_with_almost_empty,
    g_with_almost_full       => g_with_almost_full,
    g_with_count             => g_with_count,
    g_almost_empty_threshold => g_almost_empty_threshold,
    g_almost_full_threshold  => g_almost_full_threshold,
    g_register_flag_outputs  => g_register_flag_outputs)
  port map (
    rst_n_i        => tb_rst_n_i,
    clk_i          => tb_clk_i,
    d_i            => tb_d_i,
    we_i           => tb_we_i,
    q_o            => tb_q_o,
    rd_i           => tb_rd_i,
    empty_o        => tb_empty_o,
    full_o         => tb_full_o,
    almost_empty_o => tb_almost_empty_o,
    almost_full_o  => tb_almost_full_o,
    count_o        => tb_count_o
  );

  --clock and reset
  clk_proc : process
  begin
    while stop = FALSE loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_proc;

  tb_rst_n_i <= '0', '1' after 4*C_CLK_PERIOD;

  -- Stimulus for input data
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & integer'image(g_seed);
    while (NOW < 4 ms ) loop
      wait until (rising_edge (tb_clk_i) and tb_rst_n_i = '1');
      tb_d_i  <= data.randSlv(g_data_width);
      tb_wr   <= data.randSlv(1)(1);
      tb_rd   <= data.randSlv(1)(1);
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process stim;

  -- Write and Read enable
  wr_en_almost_full : if (g_with_almost_full = TRUE) generate
    tb_we_i <= tb_wr and not tb_almost_full_o;
  end generate;

  wr_en_full : if (g_with_almost_full = FALSE) generate
    tb_we_i <= tb_wr and not tb_full_o;
  end generate;

  rd_en_almost_empty : if (g_with_almost_empty = TRUE) generate
    tb_rd_i <= tb_rd and not tb_almost_empty_o;
  end generate;

  rd_en_empty : if (g_with_almost_empty = FALSE) generate
    tb_rd_i <= tb_rd and not tb_empty_o;
  end generate;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  -- Verify that FIFO is not full after system reset
  check_wr_full : process
  begin
    wait until rising_edge(tb_rst_n_i);
    assert (tb_full_o = '0')
      report "FIFO full after reset" severity failure;
    wait;
  end process;

  -- Verify that FIFO is empty after system reset
  check_rd_empty : process
  begin
    wait until rising_edge(tb_rst_n_i);
    assert (tb_empty_o)
      report "FIFO not empty after reset" severity failure;
    wait;
  end process;

  -- Verify that we are not writing in a full FIFO
  wr_in_full_fifo : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      assert (NOT(tb_we_i = '1' AND tb_full_o = '1'))
        report "Can not write in a full FIFO"
        severity failure;
    end if;
  end process;

  -- Verify that we don't read an empty FIFO
  rd_empty_fifo : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      assert (NOT(tb_rd_i = '1' AND tb_empty_o = '1'))
        report "Can not read an empty FIFO"
        severity failure;
    end if;
  end process;

  -- Self-checking part of the testbench
  -- 1. we store the incoming data in an array
  -- 2. the position is specified by wr_ptr (wr pointer)
  -- 3. we read the data from the array when rd enable = '1'
  self_check_wr : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if (tb_we_i = '1') then
        s_arr(s_wr_ptr) <= tb_d_i;
        s_wr_ptr <= s_wr_ptr + 1;
        if (s_wr_ptr = g_size) then
          s_wr_ptr <= 0;
        end if;
      end if;
    end if;
  end process;

  self_check_rd : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if (tb_rd_i = '1') then
        if (s_arr(s_rd_ptr) = tb_q_o) then
          s_rd_ptr <= s_rd_ptr + 1;
          if (s_rd_ptr = g_size) then
            s_rd_ptr <= 0;
          end if;
        else
          report "Output RTL data = " & to_hstring(tb_q_o);
          report "TB output data  = " & to_hstring(s_arr(s_rd_ptr));
          report "found in the position = " & integer'image(s_rd_ptr);
          report "Wrong Output" severity error;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                            Coverage                                        --
  --------------------------------------------------------------------------------

  -- sets up coverpoint bins
  -- Depending on the generics, some coverage bins may never be more than one.
  -- In order to analyze the coverage report, check the test case.
  InitCoverage: process
  begin
    cp_write_while_empty.AddBins     ("Write while is empty        ",ONE_BIN);
    cp_write_while_alm_empty.AddBins ("Write while is almost empty ",ONE_BIN);
    cp_write_while_alm_full.AddBins  ("Write while is almost full  ",ONE_BIN);
    cp_read_while_full.AddBins       ("Read while is full          ",ONE_BIN);
    cp_read_while_alm_empty.AddBins  ("Read while is almost empty  ",ONE_BIN);
    cp_read_while_alm_full.AddBins   ("Read while is almost full   ",ONE_BIN);
    wait;
  end process InitCoverage;

  -- Coverpoints
  -- cover possible ways of writing
  Sample_wr: process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_write_while_empty.ICover    (to_integer(tb_we_i = '1' and tb_empty_o = '1'));
      cp_write_while_alm_empty.ICover(to_integer(tb_we_i = '1' and tb_almost_empty_o = '1'));
      cp_write_while_alm_full.ICover (to_integer(tb_we_i = '1' and tb_almost_full_o = '1'));
    end loop;
  end process;

  -- cover possible ways of reading
  sample_rd : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_read_while_full.ICover     (to_integer(tb_rd_i = '1' and tb_full_o = '1'));
      cp_read_while_alm_empty.ICover(to_integer(tb_rd_i = '1' and tb_almost_empty_o = '1'));
      cp_read_while_alm_full.ICover (to_integer(tb_rd_i = '1' and tb_almost_full_o = '1'));
    end loop;
  end process;

  -- Report of the coverage
  CoverReport: process
  begin
    wait until STOP;
    cp_write_while_empty.writebin;
    cp_write_while_alm_empty.writebin;
    cp_write_while_alm_full.writebin;
    cp_read_while_full.writebin;
    cp_read_while_alm_empty.writebin;
    cp_read_while_alm_full.writebin;
    report "PASS";
  end process;

end tb;
