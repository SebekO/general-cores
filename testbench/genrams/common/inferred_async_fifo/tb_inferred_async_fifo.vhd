--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_inferred_async_fifo
--
-- description: Testbench for the parametrizable asynchronous FIFO 
-- Dual-clock asynchronous FIFO.
-- - configurable data width and size
-- - configurable full/empty/almost full/almost empty/word count signals
--
--------------------------------------------------------------------------------
-- Copyright CERN 2011-2018
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
-------------------------------------------------------------------------------

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.genram_pkg.all;
use work.gencores_pkg.all;

--OSVMM library 
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_inferred_async_fifo
--=================================================================================================

entity tb_inferred_async_fifo is
  generic (
    g_seed_wr              : natural;
    g_seed_rd              : natural;
    g_data_width           : natural;
    g_size                 : natural;
    g_show_ahead           : boolean := FALSE;
    g_with_rd_empty        : boolean := TRUE;
    g_with_rd_full         : boolean := FALSE;
    g_with_rd_almost_empty : boolean := FALSE;
    g_with_rd_almost_full  : boolean := FALSE;
    g_with_rd_count        : boolean := FALSE;
    g_with_wr_empty        : boolean := FALSE;
    g_with_wr_full         : boolean := TRUE;
    g_with_wr_almost_empty : boolean := FALSE;
    g_with_wr_almost_full  : boolean := FALSE;
    g_with_wr_count        : boolean := FALSE;
    g_almost_empty_threshold : integer;
    g_almost_full_threshold  : integer);
end entity;

architecture tb of tb_inferred_async_fifo is

  -- constants
  constant C_CLK_WR_PERIOD : time := 5 ns;
  constant C_CLK_RD_PERIOD : time := 10 ns;

  -- singals
  signal tb_rst_n_i           : std_logic;
  signal tb_clk_wr_i          : std_logic;
  signal tb_d_i               : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
  signal tb_we_i              : std_logic;
  signal tb_wr_empty_o        : std_logic;
  signal tb_wr_full_o         : std_logic;
  signal tb_wr_almost_empty_o : std_logic;
  signal tb_wr_almost_full_o  : std_logic;
  signal tb_wr_count_o        : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal tb_clk_rd_i          : std_logic;
  signal tb_q_o               : std_logic_vector(g_data_width-1 downto 0);
  signal tb_rd_i              : std_logic;
  signal tb_rd_empty_o        : std_logic;
  signal tb_rd_full_o         : std_logic;
  signal tb_rd_almost_empty_o : std_logic;
  signal tb_rd_almost_full_o  : std_logic;
  signal tb_rd_count_o        : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');

  signal stop : boolean;
  signal tb_wr : std_logic := '0';
  signal tb_rd : std_logic := '0';
  
  -- 2D array is for self-checking purpose
  type t_array is array (0 to g_size)
          of std_logic_vector(g_data_width-1 downto 0);

  signal s_arr    : t_array := (others=>(others=>'0'));
  signal s_wr_ptr : natural := 0;
  signal s_rd_ptr : natural := 0;

  -- signals for coverage
  shared variable cp_write_while_wr_empty     : covPType;
  shared variable cp_write_while_wr_alm_empty : covPType;
  shared variable cp_write_while_wr_alm_full  : covPType;
  shared variable cp_read_while_rd_full       : covPType;
  shared variable cp_read_while_rd_alm_empty  : covPType;
  shared variable cp_read_while_rd_alm_full   : covPType;

begin

  --Unit Under Test
  UUT : entity work.inferred_async_fifo
  generic map (
    g_data_width             => g_data_width,
    g_size                   => g_size,
    g_show_ahead             => g_show_ahead,
    g_with_rd_empty          => g_with_rd_empty,
    g_with_rd_full           => g_with_rd_full,
    g_with_rd_almost_empty   => g_with_rd_almost_empty,
    g_with_rd_almost_full    => g_with_rd_almost_full,
    g_with_rd_count          => g_with_rd_count,
    g_with_wr_empty          => g_with_wr_empty,
    g_with_wr_full           => g_with_wr_full,
    g_with_wr_almost_empty   => g_with_wr_almost_empty,
    g_with_wr_almost_full    => g_with_wr_almost_full,
    g_with_wr_count          => g_with_wr_count,
    g_almost_empty_threshold => g_almost_empty_threshold,
    g_almost_full_threshold  => g_almost_full_threshold)
  port map (
    rst_n_i           => tb_rst_n_i,
    clk_wr_i          => tb_clk_wr_i,
    d_i               => tb_d_i,
    we_i              => tb_we_i,
    wr_empty_o        => tb_wr_empty_o,
    wr_full_o         => tb_wr_full_o,
    wr_almost_empty_o => tb_wr_almost_empty_o,
    wr_almost_full_o  => tb_wr_almost_full_o,
    wr_count_o        => tb_wr_count_o,
    clk_rd_i          => tb_clk_rd_i,
    q_o               => tb_q_o, 
    rd_i              => tb_rd_i,
    rd_empty_o        => tb_rd_empty_o,
    rd_full_o         => tb_rd_full_o,
    rd_almost_empty_o => tb_rd_almost_empty_o,
    rd_almost_full_o  => tb_rd_almost_full_o,
    rd_count_o        => tb_rd_count_o);

	--WR clock
	wr_clk : process
	begin
		while stop = FALSE loop
			tb_clk_wr_i <= '1';
			wait for C_CLK_WR_PERIOD/2;
			tb_clk_wr_i <= '0';
			wait for C_CLK_WR_PERIOD/2;
		end loop;
		wait;
	end process wr_clk;

  -- RD clock
	rd_clk : process
	begin
		while stop = FALSE loop
			tb_clk_rd_i <= '1';
			wait for C_CLK_RD_PERIOD/2;
			tb_clk_rd_i <= '0';
			wait for C_CLK_RD_PERIOD/2;
		end loop;
		wait;
	end process rd_clk;

  tb_rst_n_i <= '0', '1' after 4*C_CLK_WR_PERIOD;

  -- Stimulus for write side input data
	stim_wr : process
    variable data    : RandomPType;
	  variable ncycles : natural;
	begin
    data.InitSeed(g_seed_wr);
    report "[STARTING - WR] with seed = " & integer'image(g_seed_wr);
		while (NOW < 2 ms ) loop
		  wait until (rising_edge (tb_clk_wr_i) and tb_rst_n_i = '1');
		  tb_d_i  <= data.randSlv(g_data_width);
          tb_wr   <= data.randSlv(1)(1);
		  ncycles := ncycles + 1;
		end loop;
		report "[WR] Number of simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
		stop <= true;
    wait;
  end process stim_wr;

  -- Stimulus for read side input data
	stim_rd : process
    variable data    : RandomPType;
	  variable ncycles : natural;
	begin
    data.InitSeed(g_seed_rd);
    report "[STARTING - RD] with seed = " & integer'image(g_seed_rd);
		while (stop = FALSE) loop
		  wait until (rising_edge (tb_clk_rd_i) and tb_rst_n_i = '1');
          tb_rd   <= data.randSlv(1)(1);
		  ncycles := ncycles + 1;
		end loop;
		report "[RD] Number of simulation cycles = " & to_string(ncycles);
		wait;
  end process stim_rd;

  -- Write and Read enable
  wr_en_almost_full : if (g_with_wr_almost_full = TRUE) generate
    tb_we_i <= tb_wr and not tb_wr_almost_full_o and not tb_wr_full_o;
  end generate;

  wr_en_full : if (g_with_wr_almost_full = FALSE) generate
    tb_we_i <= tb_wr and not tb_wr_full_o;
  end generate;

  rd_en_almost_empty : if (g_with_rd_almost_empty = TRUE) generate
    tb_rd_i <= tb_rd and not tb_rd_almost_empty_o and not tb_rd_empty_o;
  end generate;

  rd_en_empty : if (g_with_rd_almost_empty = FALSE) generate
    tb_rd_i <= tb_rd and not tb_rd_empty_o;
  end generate;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  -- Verify that FIFO is not full after system reset
  check_wr_full : process
  begin
    wait until rising_edge(tb_rst_n_i);
    assert (tb_wr_full_o = '0')
      report "WR SIDE: FIFO full after reset" severity failure;
    wait;
  end process;

  -- Verify that FIFO is empty after system reset
  check_rd_empty : process
  begin
    wait until rising_edge(tb_rst_n_i);
    assert (tb_rd_empty_o)
      report "RD SIDE: FIFO not empty after reset" severity failure;
    wait;
  end process;

  -- Verify that we are not writing in a full FIFO
  wr_in_full_fifo : process(tb_clk_wr_i)
  begin
    if rising_edge(tb_clk_wr_i) then
      assert (NOT(tb_we_i = '1' AND tb_wr_full_o = '1'))
        report "WR SIDE: Can not write in a full FIFO" 
        severity failure;
    end if;
  end process;

  -- Verify that we don't read an empty FIFO
  rd_empty_fifo : process(tb_clk_wr_i)
  begin
    if rising_edge(tb_clk_rd_i) then
      assert (NOT(tb_rd_i = '1' AND tb_rd_empty_o = '1'))
        report "Can not read an empty FIFO"
        severity failure;
    end if;
  end process;

  -- Self-checking part of the testbench
  -- 1. we store the incoming data in an array
  -- 2. the position is specified by wr_ptr (wr pointer)
  -- 3. we read the data from the array when rd enable = '1'
  self_check_wr : process(tb_clk_wr_i)
  begin
    if rising_edge(tb_clk_wr_i) then
      if (tb_we_i = '1') then
        s_arr(s_wr_ptr) <= tb_d_i;
        s_wr_ptr <= s_wr_ptr + 1;
        if (s_wr_ptr = g_size) then
          s_wr_ptr <= 0;
        end if;
      end if;
    end if;
  end process;

  no_almost_empty_full : if (g_with_wr_almost_empty = false 
                       or g_with_rd_almost_empty = false
                       or g_with_wr_almost_full= false
                       or g_with_rd_almost_full= false) generate

    self_check_rd : process(tb_clk_rd_i)
    begin
     if rising_edge(tb_clk_rd_i) then
        if (tb_rd_i = '1' ) then
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
  end generate;


  almost_empty_full : if (g_with_wr_almost_empty = true 
                       or g_with_rd_almost_empty = true
                       or g_with_wr_almost_full= true
                       or g_with_rd_almost_full= true)
                      AND g_show_ahead = FALSE generate

    self_check_rd : process
    begin
      while (stop = FALSE) loop
        wait until rising_edge(tb_clk_rd_i); 
        if (tb_rd_i = '1' ) then
          wait for C_CLK_RD_PERIOD;
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
      end loop;
      wait;
    end process;

end generate;

  --------------------------------------------------------------------------------
  --                            Coverage                                        --
  --------------------------------------------------------------------------------

  -- sets up coverpoint bins
  -- Depending on the generics, some coverage bins may never be more than one.
  -- In order to analyze the coverage report, check the test case.
  InitCoverage: process
  begin
    cp_write_while_wr_empty.AddBins     ("Write while wr is empty        ",ONE_BIN);
    cp_write_while_wr_alm_empty.AddBins ("Write while wr is almost empty ",ONE_BIN);
    cp_write_while_wr_alm_full.AddBins  ("Write while wr is almost full  ",ONE_BIN);
    cp_read_while_rd_full.AddBins       ("Read while rd is almost empty  ",ONE_BIN);
    cp_read_while_rd_alm_empty.AddBins  ("Read while rd is not empty     ",ONE_BIN);
    cp_read_while_rd_alm_full.AddBins   ("Read while rd is almost full   ",ONE_BIN);
    wait;
  end process InitCoverage;

  -- Coverpoints
  -- cover possible ways of writing
  Sample_wr: process
  begin
    loop
      wait until rising_edge(tb_clk_wr_i);
      cp_write_while_wr_empty.ICover    (to_integer(tb_we_i = '1' and tb_wr_empty_o = '1'));
      cp_write_while_wr_alm_empty.ICover(to_integer(tb_we_i = '1' and tb_wr_almost_empty_o = '1'));
      cp_write_while_wr_alm_full.ICover (to_integer(tb_we_i = '1' and tb_wr_almost_full_o = '1'));
    end loop;
  end process;

  -- cover possible ways of reading
  sample_rd : process
  begin
    loop
      wait until rising_edge(tb_clk_rd_i);
      cp_read_while_rd_full.ICover     (to_integer(tb_rd_i = '1' and tb_rd_almost_empty_o = '1'));
      cp_read_while_rd_alm_empty.ICover(to_integer(tb_rd_i = '1' and tb_rd_empty_o = '0'));
      cp_read_while_rd_alm_full.ICover (to_integer(tb_rd_i = '1' and tb_wr_almost_full_o = '1'));
    end loop;
  end process;

  -- Report of the coverage
  CoverReport: process
  begin
    wait until STOP;
    cp_write_while_wr_empty.writebin;
    cp_write_while_wr_alm_empty.writebin;
    cp_write_while_wr_alm_full.writebin;
    cp_read_while_rd_full.writebin;
    cp_read_while_rd_alm_empty.writebin;
    cp_read_while_rd_alm_full.writebin;
    report "PASS";
  end process;

end tb;

