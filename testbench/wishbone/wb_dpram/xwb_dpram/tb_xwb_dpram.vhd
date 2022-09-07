-------------------------------------------------------------------------------
-- Title      : Testbench for dual-port RAM for WR core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : tb_xwb_dpram.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2022-03-28
-- Platform   : FPGA-generics
-- Standard   : VHDL '08
-------------------------------------------------------------------------------
-- Description:
--
-- Testbench for a dual port RAM with wishbone interface
-------------------------------------------------------------------------------
-- Copyright (c) 2011-2017 CERN
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

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.memory_loader_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_xwb_dpram
--=================================================================================================

entity tb_xwb_dpram is
  generic (
    g_seed_1                : natural;
    g_seed_2                : natural;
    g_size                  : natural;
    g_init_file             : string  := "";
    g_must_have_init_file   : boolean := true;
    g_slave1_interface_mode : t_wishbone_interface_mode;
    g_slave2_interface_mode : t_wishbone_interface_mode;
    g_slave1_granularity    : t_wishbone_address_granularity;
    g_slave2_granularity    : t_wishbone_address_granularity);
end entity;


--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_xwb_dpram is

  -- Constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;
  constant C_WISHBONE_SLAVE_I : t_wishbone_slave_in :=     
  ('0', '0', x"00000000", x"0", '0', x"00000000");
  constant C_WISHBONE_MASTER_O: t_wishbone_master_in :=
  ('0', '0', '0', '0', x"00000000");

  constant C_NUM_BYTES   :integer := (c_wishbone_data_width+7)/8;
  
  -- Functions
  function f_num_byte_address_bits
    return integer is
  begin
    case c_wishbone_data_width is
      when 8      => return 0;
      when 16     => return 1;
      when 32     => return 2;
      when 64     => return 3;
      when others =>
        report "wb_slave_adapter: invalid c_wishbone_data_width (we support 8, 16, 32 and 64)" severity failure;
    end case;
    return 0;
  end function f_num_byte_address_bits;

  -- Types
  type t_split_ram is array(0 to g_size-1) of std_logic_vector(7 downto 0);
  type t_split_ram_array is array(0 to 3) of t_split_ram;

  -- Signals
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_slave1_i  : t_wishbone_slave_in := C_WISHBONE_SLAVE_I;
  signal tb_slave1_o  : t_wishbone_slave_out:= C_WISHBONE_MASTER_O;
  signal tb_slave2_i  : t_wishbone_slave_in := C_WISHBONE_SLAVE_I;
  signal tb_slave2_o  : t_wishbone_slave_out:= C_WISHBONE_MASTER_O;
  signal stop         : boolean;
  signal s_ack_1      : std_logic := '0';
  signal s_ack_2      : std_logic := '0';
  signal s_dat_a      : std_logic_vector(c_wishbone_data_width-1 downto 0); 
  signal s_dat_b      : std_logic_vector(c_wishbone_data_width-1 downto 0);
  signal s_we_a       : std_logic_vector(C_NUM_BYTES -1 downto 0);
  signal s_we_b       : std_logic_vector(C_NUM_BYTES -1 downto 0);
  signal wea_rep      : std_logic_vector(C_NUM_BYTES -1 downto 0);
  signal web_rep      : std_logic_vector(C_NUM_BYTES -1 downto 0);
  signal s_int_a      : natural;
  signal s_int_b      : natural;
  signal s_wea        : std_logic;
  signal s_web        : std_logic;
  signal s_bwea       : std_logic_vector(3 downto 0);
  signal s_bweb       : std_logic_vector(3 downto 0);
  signal s_aa         : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal s_ab         : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal s_adr1       : std_logic_vector(c_wishbone_address_width-1 downto 0) := (others=>'0');
  signal s_adr2       : std_logic_vector(c_wishbone_address_width-1 downto 0) := (others=>'0');

  --  shared variable s_ram       : t_ram_type := f_file_to_ramtype;
  shared variable s_split_ram : t_split_ram_array := (0 => (others=>(others=>'0')),
                                                      1 => (others=>(others=>'0')),
                                                      2 => (others=>(others=>'0')),
                                                      3 => (others=>(others=>'0')));

begin

  -- Unit Under Test
  UUT : entity work.xwb_dpram
  generic map (
    g_size                  => g_size,
    g_init_file             => g_init_file,
    g_must_have_init_file   => g_must_have_init_file,
    g_slave1_interface_mode => g_slave1_interface_mode,
    g_slave2_interface_mode => g_slave2_interface_mode,
    g_slave1_granularity    => g_slave1_granularity,
    g_slave2_granularity    => g_slave2_granularity)
  port map (
    clk_sys_i => tb_clk_sys_i,
    rst_n_i   => tb_rst_n_i,
    slave1_i  => tb_slave1_i,
    slave1_o  => tb_slave1_o,
    slave2_i  => tb_slave2_i,
    slave2_o  => tb_slave2_o);

  -- Clock generation
  clk_sys_proc : process
  begin
    while not stop loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process clk_sys_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_SYS_PERIOD;

  -- Stimulus for Slave 1
  stim_slave1 : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed_1);
    report "[STARTING] with seed = " & to_string(g_seed_1);
    wait until tb_rst_n_i = '1';
    while NOW < 0.5 ms loop
      wait until rising_edge(tb_clk_sys_i);
      tb_slave1_i.cyc <= data.randSlv(1)(1);
      tb_slave1_i.stb <= data.randSlv(1)(1);
      tb_slave1_i.we  <= data.randSlv(1)(1);
      tb_slave1_i.sel <= data.randSlv(c_wishbone_address_width/8);
      tb_slave1_i.adr <= data.randSlv(c_wishbone_address_width);
      tb_slave1_i.dat <= data.randSlv(c_wishbone_data_width);
      ncycles         := ncycles + 1;
    end loop;
    report "[SLAVE 1] Number of simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS!";
    wait;
  end process stim_slave1;

  -- Stimulus for Slave 2
  stim_slave2 : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed_2);
    report "[STARTING] with seed = " & to_string(g_seed_2);
    wait until tb_rst_n_i = '1';
    while not stop loop
      wait until rising_edge(tb_clk_sys_i);
      tb_slave2_i.cyc <= data.randSlv(1)(1);
      tb_slave2_i.stb <= data.randSlv(1)(1);
      tb_slave2_i.we  <= data.randSlv(1)(1);
      tb_slave2_i.sel <= data.randSlv(c_wishbone_address_width/8);
      tb_slave2_i.adr <= data.randSlv(c_wishbone_address_width);
      tb_slave2_i.dat <= data.randSlv(c_wishbone_data_width);
      ncycles         := ncycles + 1;
    end loop;
    report "[SLAVE 2] Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process stim_slave2;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  -- Err, Rty and stall of the output slaves must be '0'
  -- as it is specified in the RTL core
  check_err_rty_stall : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      assert (tb_slave1_o.err = '0' and tb_slave1_o.rty = '0'
          and tb_slave1_o.stall = '0')
        report "Slave1: Err, Rty or Stall is asserted" severity error;

      assert (tb_slave2_o.err = '0' and tb_slave2_o.rty = '0'
          and tb_slave2_o.stall = '0')
        report "Slave2: Err, Rty or Stall is asserted" severity error;
    end if;
  end process;

  -- Acknowledge signals depend on interface mode of each slave
  ack_proc : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '0' then
        s_ack_1 <= '0';
        s_ack_2 <= '0';
      else
        -- Slave 1
        if (tb_slave1_o.ack = '1' and g_slave1_interface_mode = CLASSIC) then
          s_ack_1 <= '0';
        else
          s_ack_1 <= tb_slave1_i.cyc and tb_slave1_i.stb; --output of U_ADAPTER1
        end if;
        -- Slave 2
        if (tb_slave2_o.ack = '1' and g_slave2_interface_mode = CLASSIC) then
          s_ack_2 <= '0';
        else
          s_ack_2 <= tb_slave2_i.cyc and tb_slave2_i.stb; --output of U_ADAPTER2
        end if;
      end if;
    end if;
  end process;

  -- Check that output ack signals have the same
  -- behavior as the ones from RTL
  check_ack : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '1' then
        assert (s_ack_1 = tb_slave1_o.ack)
          report "Slave1: ACK mismatch" severity error;
        assert (s_ack_2 = tb_slave2_o.ack)
          report "Slave2: ACK mismatch" severity error;
      end if;
    end if;
  end process;

  -- Depending the values of the generics (interface mode and granularity),
  -- the behavior of the output data of the slaves can differ. For this reason,
  -- we can end up to the test cases that generic_dpram has

  s_bwea <= tb_slave1_i.sel when s_wea = '1' else f_zeros(c_wishbone_data_width/8);
  s_bweb <= tb_slave2_i.sel when s_web = '1' else f_zeros(c_wishbone_data_width/8);

  s_wea <= tb_slave1_i.we and tb_slave1_i.stb and tb_slave1_i.cyc;
  s_web <= tb_slave2_i.we and tb_slave2_i.stb and tb_slave2_i.cyc;


  -- 1) Split ram approach

  wea_rep <= (others => s_wea);
  web_rep <= (others => s_web);

  s_we_a <= s_bwea and wea_rep;
  s_we_b <= s_bweb and web_rep;

  s_aa <= s_adr1(f_log2_size(g_size)-1 downto 0); 
  s_ab <= s_adr2(f_log2_size(g_size)-1 downto 0); 

  s_int_a <= f_check_bounds(to_integer(unsigned(s_aa)), 0, g_size-1);
  s_int_b <= f_check_bounds(to_integer(unsigned(s_ab)), 0, g_size-1);


  -- Processes to create two RAMs to store the data
  ram_port_a : for i in 0 to 3 generate

      port_a : process(tb_clk_sys_i)
      begin
        if rising_edge(tb_clk_sys_i) then
          s_dat_a((i+1)*8-1 downto i*8) <= s_split_ram(i)(s_int_a);
          if s_we_a(i) = '1' then
            s_split_ram(i)(s_int_a) := tb_slave1_i.dat((i+1)*8-1 downto i*8);
          end if;
        end if;
      end process;
  
  end generate ram_port_a;

  ram_port_b : for j in 0 to 3 generate

    port_b : process(tb_clk_sys_i)
    begin
      if rising_edge(tb_clk_sys_i) then
        s_dat_b((j+1)*8-1 downto j*8) <= s_split_ram(j)(s_int_b);
        if s_we_b(j) = '1' then
          s_split_ram(j)(s_int_b) := tb_slave2_i.dat((j+1)*8-1 downto j*8);
        end if;
      end if;
    end process;

  end generate ram_port_b;

  -- When the granularities are not equal, different addresses coming
  -- out from the U_ADAPTER(s). For that reason, these addresses
  -- need to be calculated 
  
  word_gran_addr1 : if (g_slave1_granularity = WORD) generate

    s_adr1 <= tb_slave1_i.adr;
             
  end generate;

  word_gran_addr2 : if (g_slave2_granularity = WORD) generate

    s_adr2 <= tb_slave2_i.adr;

  end generate;

  byte_gran_addr1 : if (g_slave1_granularity = BYTE) generate

    s_adr1 <= "00" & tb_slave1_i.adr(31 downto 2); 

  end generate;

  byte_gran_addr2 : if (g_slave2_granularity = BYTE) generate

    s_adr2 <= "00" & tb_slave2_i.adr(31 downto 2);

  end generate;


 
  -- No matter what approach is being tested, the output of the RTL should be
  -- the same with the one from the testbench in order to be sure that the 
  -- behavior of both are the correct

  -- Port A
  check_out_data_a : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      assert (s_dat_a = tb_slave1_o.dat)
        report "PORT A: Data mismatch" severity error;
    end if;
  end process;

  -- Port B
  check_out_data_b : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      assert (s_dat_b = tb_slave2_o.dat)
        report "PORT B: Data mismatch" severity error;
    end if;
  end process;

end tb;
