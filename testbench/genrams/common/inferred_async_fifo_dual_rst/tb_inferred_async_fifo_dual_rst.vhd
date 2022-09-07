--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_generic_async_fifo_dual_rst
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- description: Testbench for Parametrizable asynchronous FIFO (Generic version).
-- Dual-clock asynchronous FIFO.
-- - configurable data width and size
-- - configurable full/empty/almost full/almost empty/word count signals
-- - dual sunchronous reset
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
--                        Entity declaration for tb_inferred_async_fifo_dual_rst
--=================================================================================================

entity tb_inferred_async_fifo_dual_rst is
	generic (
    g_seed_wr                : natural;
    g_seed_rd                : natural;
		g_data_width             : natural;
		g_size                   : natural;
		g_show_ahead             : boolean := FALSE;
		g_with_rd_empty          : boolean := TRUE;
		g_with_rd_full           : boolean := FALSE;
		g_with_rd_almost_empty   : boolean := FALSE;
		g_with_rd_almost_full    : boolean := FALSE;
		g_with_rd_count          : boolean := FALSE;
		g_with_wr_empty          : boolean := FALSE;
		g_with_wr_full           : boolean := TRUE;
		g_with_wr_almost_empty   : boolean := FALSE;
		g_with_wr_almost_full    : boolean := FALSE;
		g_with_wr_count          : boolean := FALSE;
		g_almost_empty_threshold : integer := 0;
		g_almost_full_threshold  : integer := 0);
end entity;

--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_inferred_async_fifo_dual_rst is

  -- Constants
  constant C_CLK_WR_PERIOD : time := 10 ns;
  constant C_CLK_RD_PERIOD : time := 5  ns;

	-- Signals
	signal tb_rst_wr_n_i        : std_logic;
  signal tb_clk_wr_i          : std_logic;
  signal tb_d_i               : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
  signal tb_we_i              : std_logic := '0';
  signal tb_wr_empty_o        : std_logic := '0';
	signal tb_wr_full_o         : std_logic := '0';
  signal tb_wr_almost_empty_o : std_logic := '0';
  signal tb_wr_almost_full_o  : std_logic := '0';
  signal tb_wr_count_o        : std_logic_vector(f_log2_size(g_size)-1 downto 0);
  signal tb_rst_rd_n_i        : std_logic := '0';
  signal tb_clk_rd_i          : std_logic := '0';
  signal tb_q_o               : std_logic_vector(g_data_width-1 downto 0);
  signal tb_rd_i              : std_logic := '0';
  signal tb_rd_empty_o        : std_logic := '0';
  signal tb_rd_full_o         : std_logic := '0';
  signal tb_rd_almost_empty_o : std_logic := '0';
  signal tb_rd_almost_full_o  : std_logic := '0';
  signal tb_rd_count_o        : std_logic_vector(f_log2_size(g_size)-1 downto 0);
	signal stop                 : boolean;
  signal s_wren               : std_logic := '0';
  signal s_rden               : std_logic := '0';

  shared variable cp_rst_wr_i              : covPType;
	shared variable cp_rst_rd_i              : covPType;
  shared variable cp_write_while_empty     : covPType;
  shared variable cp_write_while_alm_empty : covPType;
  shared variable cp_write_while_alm_full  : covPType;
  shared variable cp_read_while_full       : covPType;
  shared variable cp_read_while_alm_empty  : covPType;
  shared variable cp_read_while_alm_full   : covPType;

	--2D array is for self-checking purposes
	type t_memory is array (0 to g_size) 
			of std_logic_vector(g_data_width-1 downto 0);

	--Declare and initialize the array
	signal s_mem : t_memory   := (others=>(others=>'0'));	
	signal wr_ptr : natural   := 0;
	signal rd_ptr : natural   := 0;
  signal s_rd_i : std_logic := '0';        

begin
	
  --Unit Under Test
	UUT : entity work.inferred_async_fifo_dual_rst
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
	 	rst_wr_n_i        => tb_rst_wr_n_i,
  	clk_wr_i          => tb_clk_wr_i,
  	d_i               => tb_d_i,
  	we_i              => tb_we_i,
  	wr_empty_o        => tb_wr_empty_o,
  	wr_full_o         => tb_wr_full_o,
  	wr_almost_empty_o => tb_wr_almost_empty_o,
    wr_almost_full_o  => tb_wr_almost_full_o,
    wr_count_o        => tb_wr_count_o,
    rst_rd_n_i        => tb_rst_rd_n_i,
    clk_rd_i          => tb_clk_rd_i,
    q_o               => tb_q_o,
    rd_i              => tb_rd_i,
    rd_empty_o        => tb_rd_empty_o,
  	rd_full_o         => tb_rd_full_o,
  	rd_almost_empty_o => tb_rd_almost_empty_o,
  	rd_almost_full_o  => tb_rd_almost_full_o,
  	rd_count_o        => tb_rd_count_o);

	--Write clock generation
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

  -- Write reset generation
	tb_rst_wr_n_i <= '0', '1' after 2*C_CLK_WR_PERIOD;

  -- Read clock generation
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

  -- Read reset generation
	tb_rst_rd_n_i <= '0', '1' after 2*C_CLK_RD_PERIOD;

  --Stimulus for write side
	stim_wr : process
	  variable data    : RandomPType;
		variable ncycles : natural;
	begin
    data.InitSeed(g_seed_wr);
    report "[STARTING - WR] with seed = " & to_string(g_seed_wr);
		while (NOW < 0.1 ms ) loop
			wait until (rising_edge (tb_clk_wr_i) and tb_rst_wr_n_i = '1');
			tb_d_i  <= data.randSlv(g_data_width);
		  s_wren <= data.randSlv(1)(1);
			ncycles := ncycles + 1;
		end loop;
		report "Number of simulation cycles = " & to_string(ncycles);
		stop <= TRUE;
    report "Test PASS!";
		wait;
	end process stim_wr;

  -- Stimulus for read side input data
	stim_rd : process
    variable data    : RandomPType;
	  variable ncycles : natural;
	begin
    data.InitSeed(g_seed_rd);
    report "[STARTING - RD] with seed = " & to_string(g_seed_rd);
		while (stop = FALSE) loop
		  wait until (rising_edge (tb_clk_rd_i) and tb_rst_rd_n_i = '1');
      s_rden <= data.randSlv(1)(1);
		  ncycles := ncycles + 1;
		end loop;
		report "[RD] Number of simulation cycles = " & to_string(ncycles);
		wait;
  end process stim_rd;
	
  -- Write and Read enable signals
  wr_en_almost_full : if (g_with_wr_almost_full = TRUE) generate
    tb_we_i <= s_wren and not tb_wr_almost_full_o and not tb_wr_full_o;
  end generate;

  wr_en_full : if (g_with_wr_almost_full = FALSE) generate
    tb_we_i <= s_wren and not tb_wr_full_o;
  end generate;

  rd_en_almost_empty : if (g_with_rd_almost_empty = TRUE) generate
    tb_rd_i <= s_rden and not tb_rd_almost_empty_o and not tb_rd_empty_o;
  end generate;

  rd_en_empty : if (g_with_rd_almost_empty = FALSE) generate
    tb_rd_i <= s_rden and not tb_rd_empty_o;
  end generate;

	-- Self-Checking part of testbench
  -- 1. we store the incoming data in an array
  -- 2. the position specified by wr_ptr
  -- 3. we read the data from the array when RD = '1'
  -- 4. everything happes in different process
  -- note: there are two different reading processes
  -- depending the value of g_show_ahead
	self_check_wr : process(tb_clk_wr_i)
	begin
		if rising_edge(tb_clk_wr_i) then
			if (tb_we_i = '1') then
				s_mem(wr_ptr) <= tb_d_i;
				wr_ptr <= wr_ptr + 1;
				if wr_ptr = g_size then
					wr_ptr <= 0;
				end if;
			end if;
		end if;
	end process;


  self_check_rd_show_ahead : if (g_show_ahead = TRUE) generate
	  
    process
	  begin
      while not stop loop
		    wait until rising_edge(tb_clk_rd_i);
			  if tb_rd_i = '1' then
				  if s_mem(rd_ptr) = tb_q_o then
            rd_ptr <= rd_ptr + 1;
            if rd_ptr = g_size then
              rd_ptr <= 0;
            end if;
          else
					  report "tb_q_o = " & to_hstring(tb_q_o);
					  report "found in the position = " & integer'image(rd_ptr);
            report "s_mem(rd_ptr)         = " & to_hstring(s_mem(rd_ptr));
					  report "Wrong Output"
					  severity error;
				  end if;
			  end if;
      end loop;
      wait;
	  end process;
  end generate self_check_rd_show_ahead;

  self_check_rd_no_show_ahead : if (g_show_ahead = FALSE) generate
    
    process
    begin
      while not stop loop
        wait until rising_edge(tb_clk_rd_i);
        if tb_rd_i = '1' then
          wait for C_CLK_RD_PERIOD;
          if s_mem(rd_ptr) = tb_q_o then
            rd_ptr <= rd_ptr + 1;
            if rd_ptr = g_size then
              rd_ptr <= 0;
            end if;
          else
					  report "tb_q_o = " & to_hstring(tb_q_o);
					  report "found in the position = " & integer'image(rd_ptr);
					  report "Wrong Output"
					  severity error;
				  end if;
        end if;
      end loop;
      wait;
    end process;
  end generate;

  --------------------------------------------------------------------------------
	--                                Assertions                                  --
  --------------------------------------------------------------------------------
  
  -- Verify that FIFO is not full after reset
  check_wr_full : process
  begin
    wait until (rising_edge(tb_rst_wr_n_i));
    assert (tb_wr_full_o='0')
      report "Write side : It is full in the beginning"
      severity failure;
    wait;
  end process;

  -- Verify that FIFO is empty after reset
  check_rd_empty : process
  begin
    wait until (rising_edge(tb_rst_rd_n_i));
    assert (tb_rd_empty_o)
      report "Read side : It is not empty in the beginning"
      severity failure;
      wait;
  end process;

  -- Verify that we don't write in a full FIFO
  write_in_full_fifo : process(tb_clk_wr_i)
  begin
    if (rising_edge(tb_clk_wr_i)) then
      assert (not(tb_we_i='1' and tb_wr_full_o='1') )
        report "Can not write in a FULL fifo"
        severity failure;
    end if;
  end process;

  -- Verify that we don't read an empty FIFO
  read_empty_fifo : process (tb_clk_rd_i)
  begin
    if (rising_edge(tb_clk_rd_i)) then
      assert (not(tb_rd_i = '1' and tb_rd_empty_o = '1'))
        report "Can not read an empty fifo"
        severity failure;
    end if;
  end process;

  -- sets up coverpoint bins
  -- Depending on the generics, some coverage bins may never be more than one.
  -- the correct way to advise the coverage here, is by looking at the generics first
  InitCoverage: process 
  begin        
    cp_rst_wr_i.AddBins             ("write side reset is HIGH"              ,ONE_BIN);
	  cp_rst_rd_i.AddBins             ("read side reset is HIGH"               ,ONE_BIN);
    cp_write_while_empty.AddBins    ("Write while write side is empty"       ,ONE_BIN);
    cp_write_while_alm_empty.AddBins("Write while write side is almost empty",ONE_BIN);
    cp_write_while_alm_full.AddBins ("Write while write side is almost full" ,ONE_BIN);
    cp_read_while_full.AddBins      ("Read while read side is full"          ,ONE_BIN);
    cp_read_while_alm_empty.AddBins ("Read while read side is almost empty"  ,ONE_BIN);
    cp_read_while_alm_full.AddBins  ("Read while read side is almost full"   ,ONE_BIN);
    wait;
  end process InitCoverage;

  -- Coverpoints
  -- This is working when the clocking period of WR/RD is not the same
  sample_rst : process(tb_rst_wr_n_i,tb_rst_rd_n_i)
  begin
    if (rising_edge(tb_rst_wr_n_i)) then
      cp_rst_wr_i.ICover(to_integer(tb_rst_wr_n_i = '1'));
    end if;
    if (rising_edge(tb_rst_rd_n_i)) then
      cp_rst_rd_i.ICover(to_integer(tb_rst_rd_n_i = '1'));
    end if;
  end process sample_rst;

  Sample_wr: process
  begin
    loop
      wait until (rising_edge(tb_clk_wr_i));         
      cp_write_while_empty.ICover    (to_integer(tb_we_i = '1' and tb_wr_empty_o = '1')); 
      cp_write_while_alm_empty.ICover(to_integer(tb_we_i = '1' and tb_wr_almost_empty_o = '1')); 
      cp_write_while_alm_full.ICover (to_integer(tb_we_i = '1' and tb_wr_almost_full_o = '1')); 
    end loop;
  end process;

  sample_rd : process
  begin
    loop
      wait until rising_edge(tb_clk_rd_i);
      cp_read_while_full.ICover     (to_integer(tb_rd_i = '1' and tb_rd_full_o = '1')); 
      cp_read_while_alm_empty.ICover(to_integer(tb_rd_i = '1' and tb_rd_almost_empty_o = '1'));
      cp_read_while_alm_full.ICover (to_integer(tb_rd_i = '1' and tb_rd_almost_full_o = '1'));  
    end loop;
  end process;

  CoverReport: process
  begin
    wait until STOP;
    cp_rst_wr_i.writebin;
	  cp_rst_rd_i.writebin;
    cp_write_while_empty.writebin;
    cp_write_while_alm_empty.writebin;
    cp_write_while_alm_full.writebin;
    cp_read_while_full.writebin;
    cp_read_while_alm_empty.writebin;
    cp_read_while_alm_full.writebin;
    report "PASS";
  end process;

end tb;
