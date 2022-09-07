-------------------------------------------------------------------------------
-- Title      : Testbench Parametrizable dual-port synchronous RAM (Xilinx version)
-- Project    : Generics RAMs and FIFOs collection
-------------------------------------------------------------------------------
-- File       : tb_generic_simple_dpram.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2022-03-25
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Testbench for a true dual-port synchronous RAM for Xilinx with:
-- - configurable address and data bus width
-- - byte-addressing mode (data bus width restricted to multiple of 8 bits)
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CERN
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
-------------------------------------------------------------------------------

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.genram_pkg.all;
use work.memory_loader_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_generic_simple_dpram
--=================================================================================================

entity tb_generic_simple_dpram is
  generic (
    g_seed_a                   : natural;
    g_seed_b                   : natural;
    -- standard parameters
    g_data_width               : natural := 32;
    g_size                     : natural := 16384;

    g_with_byte_enable         : boolean := false;
    g_addr_conflict_resolution : string  := "read_first";
    g_init_file                : string  := "";
    g_dual_clock               : boolean := true;
    g_fail_if_file_not_found   : boolean := true);
end entity;

--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_generic_simple_dpram is


  -- Constants
  constant C_CLKA_PERIOD : time   := 10 ns;
  constant C_CLKB_PERIOD : time   := 8 ns;
  
  -- Types
  type t_ram_type is array(0 to g_size-1) of std_logic_vector(g_data_width-1 downto 0);

  -- Functions  
  impure function f_file_to_ramtype return t_ram_type is
    variable tmp    : t_ram_type;
    variable n, pos : integer;
    variable mem32  : t_ram32_type(0 to g_size-1);
    variable mem16  : t_ram16_type(0 to g_size-1);
    variable mem8   : t_ram8_type(0 to g_size-1);
    variable arr    : t_meminit_array(0 to g_size-1, g_data_width-1 downto 0);
  begin
    -- If no file was given, there is nothing to convert, just return
    if (g_init_file = "" or g_init_file = "none") then
      tmp := (others=>(others=>'0'));
      return tmp;
    end if;

    arr := f_load_mem_from_file(g_init_file, g_size, g_data_width, g_fail_if_file_not_found);
    pos := 0;
    while(pos < g_size)loop
      n := 0;
      -- avoid ISE loop iteration limit
      while (pos < g_size and n < 4096) loop
        for i in 0 to g_data_width-1 loop
          tmp(pos)(i) := arr(pos, i);
        end loop;  -- i
        n   := n+1;
        pos := pos + 1;
      end loop;
    end loop;
    return tmp;
  end f_file_to_ramtype;


  -- Signals
  signal tb_rst_n_i : std_logic := '1';
  -- Port A
  signal tb_clka_i  : std_logic;
  signal tb_bwea_i  : std_logic_vector((g_data_width+7)/8-1 downto 0)  := (others=>'0');
  signal tb_wea_i   : std_logic;
  signal tb_aa_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal tb_da_i    : std_logic_vector(g_data_width-1 downto 0)        := (others=>'0');
  -- Port B
  signal tb_clkb_i  : std_logic;
  signal tb_ab_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal tb_qb_o    : std_logic_vector(g_data_width-1 downto 0);

  signal stop       : boolean;
  signal s_dat_o    : std_logic_vector(g_data_width-1 downto 0)        := (others=>'0');

  shared variable s_ram : t_ram_type := f_file_to_ramtype;

begin

  -- Unit Under Test
  UUT : entity work.generic_simple_dpram
  generic map (
    g_data_width               => g_data_width,
    g_size                     => g_size,
    g_with_byte_enable         => g_with_byte_enable,
    g_addr_conflict_resolution => g_addr_conflict_resolution,
    g_init_file                => g_init_file,
    g_dual_clock               => g_dual_clock,
    g_fail_if_file_not_found   => g_fail_if_file_not_found)
  port map (
    rst_n_i => tb_rst_n_i,
    clka_i  => tb_clka_i,
    bwea_i  => tb_bwea_i,
    wea_i   => tb_wea_i,
    aa_i    => tb_aa_i,
    da_i    => tb_da_i,
    clkb_i  => tb_clkb_i,
    ab_i    => tb_ab_i,
    qb_o    => tb_qb_o);

  -- Clock for port A
  clk_a : process
  begin
    while not stop loop
      tb_clka_i <= '1';
      wait for C_CLKA_PERIOD/2;
      tb_clka_i <= '0';
      wait for C_CLKB_PERIOD/2;
    end loop;
    wait;
  end process clk_a;

  -- Clock for port B
  clk_b : process
  begin
    while not stop loop
      tb_clkb_i <= '1';
      wait for C_CLKB_PERIOD/2;
      tb_clkb_i <= '0';
      wait for C_CLKB_PERIOD/2;
    end loop;
    wait;
  end process clk_b;

  -- Reset generation (use the slowest clock)
  tb_rst_n_i <= '0', '1' after 2*C_CLKA_PERIOD;

  -- Stimulus for port A
  stim_a : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed_a);
    report "[STARTING - A] with seed = " & integer'image(g_seed_a);
    wait until tb_rst_n_i;
    while NOW < 2 ms loop
      wait until rising_edge(tb_clka_i);
      tb_bwea_i <= data.randSlv((g_data_width+7)/8) when tb_wea_i = '1';
      tb_wea_i  <= data.randSlv(1)(1);
      tb_aa_i   <= data.randSlv(f_log2_size(g_size)) when tb_wea_i = '1';
      tb_da_i   <= data.randSlv(g_data_width);
      ncycles   := ncycles + 1;
      wait for C_CLKA_PERIOD;
    end loop;
    report "[A] Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    wait;
  end process stim_a;

  -- Stimulus for port B
  stim_b : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed_b);
    report "[STARTING - B] with seed = " & integer'image(g_seed_b);
    wait until tb_rst_n_i;
    while NOW < 2 ms loop
      wait until rising_edge(tb_clkb_i);
      tb_ab_i   <= data.randSlv(f_log2_size(g_size)) when tb_wea_i = '1';
      ncycles   := ncycles + 1;
      wait for C_CLKB_PERIOD;
    end loop;
    report "[B] Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process stim_b;

  --------------------------------------------------------------------------------
  --                                Assertions                                  --
  --------------------------------------------------------------------------------

  -- Store data from port A to the ram
  store_data_to_ram : process(tb_clka_i)
  begin
    if rising_edge(tb_clka_i) then
        if tb_wea_i = '1' then
          s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i when tb_wea_i = '1';
       end if;
    end if;
  end process;

  -- Assign the value from ram to a vector
  store_data_to_vector : process(tb_clkb_i)
  begin
    if rising_edge(tb_clkb_i) then
      s_dat_o <= s_ram(to_integer(unsigned(tb_ab_i)));
    end if;
  end process;

  -- Compare the output with the stored data
  check_data : process(tb_clkb_i)
  begin
    if rising_edge(tb_clkb_i) then
      if tb_rst_n_i then
        if tb_wea_i = '1' then
          assert ( tb_qb_o = s_dat_o)
            report "Data mismatch" severity error;
        end if;
      end if;
    end if;
  end process;


end tb;
