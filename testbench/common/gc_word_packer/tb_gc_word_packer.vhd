-------------------------------------------------------------------------------
-- Title      : Testbench for Word packer/unpacker
-- Project    : General Cores Collection library
-------------------------------------------------------------------------------
-- File       : tb_gc_word_packer.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2021-12-21
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for gc_word_packer. Packs/unpacks g_input_width-sized
-- word(s) into g_output_width-sized word(s). Data is packed starting from the 
-- least significant word. Packet width must be integer multiple of the 
-- unpacked width.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2022 CERN / BE-CEM-EDL
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_word_packer is
  generic (
    g_seed         : natural;
    g_input_width  : integer;
    g_output_width : integer);
end entity;

architecture tb of tb_gc_word_packer is
    
  -- functions
  function f_max(a : integer; b : integer) return integer is
  begin
    if(a > b) then
      return a;
    else
      return b;
    end if;
  end f_max;

  function f_min(a : integer; b : integer) return integer is
  begin
    if(a < b) then
      return a;
    else
      return b;
    end if;
  end f_min;

  -- constants
  constant C_CLK_PERIOD : time := 10 ns;
  constant c_sreg_size    : integer := f_max(g_input_width, g_output_width);
  constant c_sreg_entries : integer := c_sreg_size / f_min(g_input_width, g_output_width);

  -- signals
  signal tb_clk_i     : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_d_i       : std_logic_vector(g_input_width-1 downto 0) := (others=>'0');
  signal tb_d_valid_i : std_logic := '0';
  signal tb_d_req_o   : std_logic;
  signal tb_flush_i   : std_logic := '0';
  signal tb_q_o       : std_logic_vector(g_output_width-1 downto 0);
  signal tb_q_valid_o : std_logic;
  signal tb_q_req_i   : std_logic := '0';
  signal tb_q_req_d0  : std_logic := '0'; --delayed q_req_i for 1 clk cycle

  signal stop : boolean;
  -- used to store the valid input data
  signal s_data_i : std_logic_vector(c_sreg_size-1 downto 0);
  signal s_dat    : std_logic_vector(g_output_width-1 downto 0);
  signal s_cnt    : natural;
  signal s_empty  : std_logic;

begin

  -- Unit Under Test
  UUT : entity work.gc_word_packer
  generic map (
    g_input_width  => g_input_width,
    g_output_width => g_output_width)
  port map (
    clk_i     => tb_clk_i,
    rst_n_i   => tb_rst_n_i,
    d_i       => tb_d_i,
    d_valid_i => tb_d_valid_i,
    d_req_o   => tb_d_req_o,
    flush_i   => '0',
    q_o       => tb_q_o,
    q_valid_o => tb_q_valid_o,
    q_req_i   => tb_q_req_i);

  -- clock and reset behavior
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

  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  -- stimulus
  stim : process
	  variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    wait until tb_rst_n_i = '1';
    while (NOW < 4 ms) loop
	    wait until (rising_edge(tb_clk_i));
      tb_d_i       <= data.randSlv(g_input_width);
      tb_d_valid_i <= '1' when tb_d_req_o='1' else '0';
      tb_q_req_i   <= data.randSlv(1)(1);
      ncycles := ncycles + 1;
	  end loop;
	  report "Number of simulation cycles = " & to_string(ncycles);
	  stop <= TRUE;
    report "Test PASS!";
	  wait;
  end process stim;

  -- Delayed q_req_i for one clock cycle
  p_del_q_req_i : process (tb_clK_i)
  begin
    if rising_edge(tb_clK_i) then
      if tb_rst_n_i = '0' then
        tb_q_req_d0 <= '0';
      else
        tb_q_req_d0 <= tb_q_req_i;
      end if;
    end if;
  end process p_del_q_req_i;
  
  --------------------------------------------------------------------------------
  --                            Assertions                                      --
  --------------------------------------------------------------------------------

  -- Below it is checked that the generics are valid compared to the specification
  -- and that the core is working properly. Doing the packing and unpacking as it 
  -- is expected. This is tested in three different cases regarding the data width

  -- When Input is bigger than the output
  g_in_bigger : if (g_input_width > g_output_width) generate

    assert(g_input_width mod g_output_width = 0)
      report "Input bigger than output: not a multiple integer of output width"
      severity failure;

    -- stores the input valid data
    store_in_data : process(tb_clK_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '0' then
          s_data_i <= (others=>'0');
        else
          if (tb_d_valid_i='1') then
            s_data_i <= tb_d_i;
          else
            s_data_i <= s_data_i;
          end if;
        end if;
      end if;
    end process;

    -- count number of data
    cnt_nof_data : process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_q_valid_o = '1' then
          if (s_cnt = c_sreg_entries-1) then
            s_cnt <= 0;
          else
            s_cnt <= s_cnt + 1;
          end if;
        end if;
      end if;
    end process;

    -- Empty flag generation
    process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '0' then
          s_empty <= '1';
        else
          if(s_cnt = c_sreg_entries-1 and tb_d_valid_i = '0' and tb_q_req_d0 = '1') then
            s_empty <= '1';           
          elsif(tb_d_valid_i = '1') then
            s_empty <= '0';
          end if;
        end if;
      end if;
    end process;

    -- output data generation
    s_dat <= s_data_i(s_cnt*g_output_width+g_output_width-1 downto s_cnt*g_output_width) when (s_empty= '0' and tb_q_req_d0 = '1') 
             else tb_d_i(g_output_width-1 downto 0) when (tb_q_req_d0 = '1' and tb_d_valid_i = '1')
             else (others=>'X');

    -- Check that output is as expected
    check_data : process
    begin
      while not stop loop
        wait until rising_edge(tb_clk_i);
        if tb_q_valid_o = '1' then
          assert (s_dat = tb_q_o)
            report "Data mismatch" severity failure;
        end if;
      end loop;
    end process;


  end generate;

  -- When the Input is smaller than the Output
  g_in_smaller : if (g_input_width < g_output_width) generate

    assert(g_input_width mod g_output_width = g_input_width)
      report "Input smaller than output: not a multiple integer of output width"
      severity failure;
    
    -- counter calculation to find how many packets, the output will have
    cnt_data : process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '0' then
          s_cnt <= 0;
        elsif (tb_d_valid_i = '1') then
          if (s_cnt = c_sreg_entries-1 ) then
            s_cnt <= 0;
          else
            s_cnt <= s_cnt + 1;
          end if;
        end if;
      end if;
    end process;

    -- fill the vector with valid input data
    val_data : process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '0' then
          s_data_i <= (others=>'0');
        elsif (tb_d_valid_i = '1') then
          s_data_i(s_cnt*g_input_width+g_input_width-1 downto s_cnt*g_input_width) <= tb_d_i;
        end if;
      end if;
    end process;

    -- checking process
    check_data : process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '1' then
          if (tb_q_valid_o = '1') then
            assert (s_data_i = tb_q_o)
              report "Data mismatch" severity failure;
          end if;
        end if;
      end if;
    end process;

  end generate;

  -- When Input and Output are equal
  g_equal : if (g_input_width = g_output_width) generate

    assert (g_input_width-g_output_width = 0)
      report "Input width and output width are not equal"
      severity failure;

    check_proc : process(tb_clk_i)
    begin
      if (rising_edge(tb_clk_i)) then
        assert (tb_d_i = tb_q_o)
          report "DATA mismatch" severity failure;
        
        assert (tb_d_valid_i = tb_q_valid_o)
          report "Data Valid mismatch" severity failure;

        assert (tb_q_req_i = tb_d_req_o)
          report "Request mismatch" severity failure;
      end if;
    end process;

  end generate;



end tb;
