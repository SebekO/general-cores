-------------------------------------------------------------------------------
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_gc_prio_encoder.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Platform   : FPGA-generics
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Copyright (c) 2012 CERN
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_prio_encoder is
  generic (
    g_seed  : natural;
    g_width : integer := 32);
end entity;

architecture tb of tb_gc_prio_encoder is

  -- functions
  function f_count_stages(width : integer) return integer is
  begin
    if(width <= 2) then
      return 2;
    elsif(width <= 4) then
      return 3;
    elsif(width <= 8) then
      return 4;
    elsif(width <= 16) then
      return 5;
    elsif(width <= 32) then
      return 6;
    elsif(width <= 64) then
      return 7;
    elsif(width <= 128) then
      return 8;
    else
      return 0;
    end if;
  end f_count_stages;

  -- constants
  constant C_STAGES : integer := f_count_stages(g_width);

  -- signals
  signal tb_d_i     : std_logic_vector(g_width-1 downto 0) := (others=>'0');
  signal tb_therm_o : std_logic_vector(g_width-1 downto 0);
  signal stop : boolean;

  type t_stages_array is array (0 to C_STAGES) of std_logic_vector(g_width-1 downto 0);
  signal s_stage  : t_stages_array;
  signal s_data_o : std_logic_vector(g_width-1 downto 0); 
    
begin

  -- Unit Under Test
  UUT : entity work.gc_prio_encoder 
  generic map (
    g_width => g_width)
  port map (
    d_i     => tb_d_i,
    therm_o => tb_therm_o);

  -- Stimulus
	stim : process
		variable ncycles : natural;
		variable data    : RandomPType;
	begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
		while NOW < 2 ms loop
      wait for 10 ns; --give every 10ns a new input
			tb_d_i  <= data.randSlv(g_width);
			ncycles := ncycles + 1;
		end loop;
		report "Number of simulation cycles = " & to_string(ncycles);
		stop <= TRUE;
    report "Test PASS!";
		wait;
	end process;

  --------------------------------------------------------------------------------
  -- Reproduce the RTL behavior in order to compare it with the actual RTL
  --------------------------------------------------------------------------------
  s_stage(0) <= tb_d_i;

  nof_stages : for i in 1 to C_STAGES generate
    data_width : for j in 0 to g_width-1 generate
      
      case_1 :    if (j mod (2 ** i) >= (2 ** (i-1))) generate
                    s_stage(i)(j) <= s_stage(i-1)(j) or s_stage(i-1) (j - (j mod (2**i)) + (2**(i-1)) - 1);
                  end generate;
      
      case_2 :    if not (j mod (2 ** i) >= (2 ** (i-1))) generate
                    s_stage(i)(j) <= s_stage(i-1)(j);
                  end generate;
    end generate;
  end generate;
    
  s_data_o <= s_stage(C_STAGES);

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------

  assert (s_data_o = tb_therm_o)
    report "Output data mismatch" severity failure;

  assert (g_width > 0)
    report "Invalid value of data width" severity failure;

end tb;
