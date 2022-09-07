-------------------------------------------------------------------------------
-- Title      : Testbench for Simple delay line generator
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : tb_gc_delay_gen.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN BE-CEM-EDL
-- Created    : 2021-11-22
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
------------------------------------------------------------------------------
-- Description: Testbench for Simple N-bit delay line with programmable delay.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009 - 2010 CERN
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
-- Revisions  :
-- Date        Version  Author          Description
-- 2021-11-22  1.0      kblantos        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_delay_gen is 
  generic (
    g_seed         : natural;
    g_delay_cycles : natural := 2;
    g_data_width   : natural := 8);
end entity;

architecture tb of tb_gc_delay_gen is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_d_i     : std_logic_vector(g_data_width-1 downto 0);
  signal tb_q_o     : std_logic_vector(g_data_width-1 downto 0);
  
  type t_dly_array is array (0 to g_delay_cycles) of std_logic_vector(g_data_width -1 downto 0);
  signal s_dly_arr  : t_dly_array;

  signal stop       : boolean;

begin

  -- Unit Under test
  UUT : entity work.gc_delay_gen
  generic map (
    g_delay_cycles => g_delay_cycles,
    g_data_width   => g_data_width)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_n_i,
    d_i     => tb_d_i,
    q_o     => tb_q_o);

  -- Clock and reset generation
  clk_i_process : process
  begin
    while (stop = FALSE) loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
    
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while (NOW < 1 ms) loop
      wait until rising_edge(tb_clk_i) and tb_rst_n_i = '1';
      tb_d_i <= data.randSlv(g_data_width);
      ncycles := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process stim;
    
  --------------------------------------------------------------------------------
  --                         Assertions - Self Checking                         --
  --------------------------------------------------------------------------------
    
  -- Fill the array with input data
  delay_array : process (tb_clk_i, tb_rst_n_i)
  begin  
    if tb_rst_n_i = '0' then              
      for_rst : for i in 1 to g_delay_cycles loop
    	  s_dly_arr(i) <= (others => '0');
    	end loop;
    elsif rising_edge(tb_clk_i) then      
      s_dly_arr(0) <= tb_d_i;
    	for_clk : for i in 0 to g_delay_cycles-1 loop
    	  s_dly_arr(i+1) <= s_dly_arr(i);
    	end loop;
    end if;
  end process delay_array;       
    
    
  --Depending on the g_delay_cycles, we expect the output equal to input
  self_check : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) and tb_rst_n_i = '1' then
		  assert (s_dly_arr(g_delay_cycles) = tb_q_o)
		    report "Data mismatch" severity failure;
   	end if;
  end process;
    

end tb;
     

