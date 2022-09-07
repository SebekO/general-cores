-------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- Title      : Multiplexer with round-robin arbitration
-- Project    : General Cores Collection library
-------------------------------------------------------------------------------
-- File       : tb_gc_arbitrated_mux.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2020-11-17
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the arbitrated mux which is an N-channel
--              time-division multiplexer with round robin arbitration
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011 CERN / BE-CO-HT
--
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the "License") (which enables you, at your option,
-- to treat this file as licensed under the Apache License 2.0); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://solderpad.org/licenses/SHL-0.51.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--
-------------------------------------------------------------------------------
-- Revisions :
-- Date        Version  Author          Description
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.genram_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_arbitrated_mux is
  generic (
    g_seed       : natural;
    g_num_inputs : integer := 2;
    g_width      : integer := 2);
end entity;

architecture tb of tb_gc_arbitrated_mux is
  
  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i        : std_logic;
  signal tb_rst_n_i      : std_logic;
  signal tb_d_i          : std_logic_vector(g_num_inputs * g_width-1 downto 0);
  signal tb_d_valid_i    : std_logic_vector(g_num_inputs-1 downto 0);
  signal tb_d_req_o      : std_logic_vector(g_num_inputs-1 downto 0);
  signal tb_q_o          : std_logic_vector(g_width-1 downto 0);
  signal tb_q_valid_o    : std_logic;
  signal tb_q_input_id_o : std_logic_vector(f_log2_size(g_num_inputs)-1 downto 0);

  signal stop     : boolean;
  
  type t_data_array is array(0 to g_num_inputs-1) of std_logic_vector(g_width-1 downto 0);
  signal s_regs_i : t_data_array;

  signal s_data_i : std_logic_vector((g_num_inputs * g_width)-1 downto 0);
  signal s_data_o : std_logic_vector((g_num_inputs * g_width)-1 downto 0);
  signal s_cnt    : unsigned(g_num_inputs-1 downto 0) := (others=>'0');

  -- for coverage
  shared variable cp_q_valid_o : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_arbitrated_mux
  generic map (
    g_num_inputs => g_num_inputs,
    g_width      => g_width)
  port map (
    clk_i        => tb_clk_i,
    rst_n_i      => tb_rst_n_i,
    d_i          => tb_d_i,
    d_valid_i    => tb_d_valid_i,
    d_req_o      => tb_d_req_o,
    q_o          => tb_q_o,
    q_valid_o    => tb_q_valid_o,
    q_input_id_o => tb_q_input_id_o);

  -- Clock and reset
  clk_process : process
  begin
    while (stop = FALSE) loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  tb_rst_n_i <= '0', '1' after 2 * C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while (NOW < 2 ms) loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      for i in 0 to g_num_inputs-1 loop
        if tb_d_req_o(i) = '1' then
          tb_d_valid_i(i) <= data.randSlv(1)(1);
          tb_d_i          <= data.randSlv(g_num_inputs*g_width);
        else
          tb_d_valid_i <= (others=>'0');
        end if;
      end loop;
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    wait;
  end process;
     
  --------------------------------------------------------------------------    
  --                   Assertions - Self Checking                         --
  --------------------------------------------------------------------------
     
  -- Storing the valid input data in a register
  input_side : process(tb_clk_i)
	begin
	  if rising_edge(tb_clk_i) then
	    if tb_rst_n_i = '1' then
		    for i in 0 to g_num_inputs-1 loop
		      if tb_d_valid_i(i) = '1' then
		        s_regs_i(i) <= tb_d_i(g_width*(i+1)-1 downto g_width*i);
		      end if;
		    end loop;
		  end if;
		end if;
	end process;
  
  --storing the input and output valid data in registers
  creating_vectors : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_q_valid_o = '1' then
        s_cnt <= s_cnt + 1;
        if s_cnt = 0 then
          s_data_o(g_width-1 downto 0) <= tb_q_o;
          s_data_i(g_width-1 downto 0) <= s_regs_i(to_integer(s_cnt));
        elsif s_cnt < g_num_inputs then
          s_data_o((g_width)*to_integer(s_cnt)+g_width-1 downto g_width*(to_integer(s_cnt))) <= tb_q_o;
          s_data_i((g_width)*to_integer(s_cnt)+g_width-1 downto g_width*(to_integer(s_cnt))) <= s_regs_i(to_integer(s_cnt));
        else
          s_cnt <= (others=>'0');
        end if;
      else
        s_cnt <= (others=>'0');
      end if;
    end if;
  end process;

  -- Comparing the input and output
  self_check : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if falling_edge(tb_q_valid_o) then
        assert (s_data_o = s_data_i)
          report "Data mismatch" severity failure;
      end if;
    end if;
  end process;
                
  --------------------------------------------------------------------------    
  --                           Coverage                                   --
  --------------------------------------------------------------------------
    
  -- Sets up coverpoint bins
  InitCoverage : process
  begin
    cp_q_valid_o.AddBins("valid output data", ONE_BIN);
    wait;
  end process InitCoverage;
    
  -- Count the number of valid output data 
  sample : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_q_valid_o.ICover(to_integer(tb_q_valid_o = '1'));
    end loop;
  end process sample;

  -- Report of the coverage
  CoverReports : process
  begin
    wait until stop;
    report "valid output";
    cp_q_valid_o.writebin;
    report "PASS";
  end process CoverReports;
		 	 
end tb;


 
