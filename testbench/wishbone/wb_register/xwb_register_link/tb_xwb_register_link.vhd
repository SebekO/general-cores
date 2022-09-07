-------------------------------------------------------------------------------
-- Title      : A testbench for a Wishbone delay buffer
-- Project    : General Cores Library (gencores)
-------------------------------------------------------------------------------
-- File       : tb_xwb_register_link.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2022-02-01
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Testbench for a wishbone delay buffer which functionality is:
--
-- Adds registers between two wishbone interfaces.
-- Useful to improve timing closure when placed between crossbars.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2011 GSI / Wesley W. Terpstra
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_xwb_register_link is
  generic (
    g_seed               : natural;
    g_WB_IN_MODE         : t_wishbone_interface_mode      := PIPELINED;
    g_WB_IN_GRANULARITY  : t_wishbone_address_granularity := BYTE;
    g_WB_OUT_MODE        : t_wishbone_interface_mode      := PIPELINED;
    g_WB_OUT_GRANULARITY : t_wishbone_address_granularity := BYTE);
end entity;

architecture tb of tb_xwb_register_link is

  -- Constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_slave_i   : t_wishbone_slave_in;
  signal tb_slave_o   : t_wishbone_slave_out;
  signal tb_master_i  : t_wishbone_master_in;
  signal tb_master_o  : t_wishbone_master_out;
  
  signal stop         : boolean;
  signal s_slave      : t_wishbone_slave_in;
  signal s_master     : t_wishbone_master_in;
  signal s_tb_full    : std_logic;
  signal s_tb_push    : std_logic;
  signal s_tb_pop     : std_logic;
  signal s_tb_valid   : std_logic;
  signal tb_r_full0   : std_logic;
  signal tb_r_full1   : std_logic;
  signal s_tb_empty   : std_logic;

begin

  -- Unit Under Test
  UUT : entity work.xwb_register_link
  generic map (
    g_WB_IN_MODE         => g_WB_IN_MODE,
    g_WB_IN_GRANULARITY  => g_WB_IN_GRANULARITY,
    g_WB_OUT_MODE        => g_WB_OUT_MODE,
    g_WB_OUT_GRANULARITY => g_WB_OUT_GRANULARITY) 
  port map (
    clk_sys_i => tb_clk_sys_i, 
    rst_n_i   => tb_rst_n_i,
    slave_i   => tb_slave_i,
    slave_o   => tb_slave_o,
    master_i  => tb_master_i,
    master_o  => tb_master_o);

  -- Clock generation
	clk_sys_proc : process
	begin
		while STOP = FALSE loop
			tb_clk_sys_i <= '1';
			wait for C_CLK_SYS_PERIOD/2;
			tb_clk_sys_i <= '0';
			wait for C_CLK_SYS_PERIOD/2;
		end loop;
		wait;
	end process clk_sys_proc;

  -- reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_SYS_PERIOD;

  -- Stimulus
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    wait until tb_rst_n_i = '1';
    while (NOW < 0.2 ms) loop
      wait until rising_edge(tb_clk_sys_i);
      -- Slave inputs
      tb_slave_i.cyc <= data.randSlv(1)(1);
      tb_slave_i.stb <= data.randSlv(1)(1);
      tb_slave_i.we  <= data.randSlv(1)(1);
      tb_slave_i.adr <= data.randSlv(32);
      tb_slave_i.sel <= data.randSlv(4);
      tb_slave_i.dat <= data.randSlv(32);
      -- Master inputs
      tb_master_i.ack   <= data.randSlv(1)(1);
      tb_master_i.err   <= data.randSlv(1)(1);
      tb_master_i.stall <= data.randSlv(1)(1);
      tb_master_i.rty   <= data.randSlv(1)(1);
      tb_master_i.dat   <= data.randSlv(32);
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------------

  -- ensure that the output is one clock delayed compared to input
  process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if (tb_rst_n_i = '0') then
        s_slave.we  <= '0';
        s_slave.stb <= '0';
        s_slave.cyc <= '0';
        s_slave.adr <= (others=>'0');
        s_slave.sel <= (others=>'0');
        s_slave.dat <= (others=>'0');
        s_master.stall <= '0';
        s_master.rty   <= '0';
        s_master.err   <= '0';
        s_master.ack   <= '0';
        s_master.dat   <= (others=>'0');
      else
        s_slave <= tb_slave_i;
        s_master<= tb_master_i;
      end if;
    end if;
  end process;

  process
  begin
    while (stop = FALSE) loop
      wait until rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1';
      assert (tb_slave_o.dat = s_master.dat)
        report "Mismatch slave output and master input"
        severity failure;
      assert (tb_slave_o.rty = '0')
        report "RTY of slave output is not zero"
        severity failure;
    end loop;
    wait;
  end process;

  process
  begin
    while (stop = FALSE) loop
      wait until rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1';
      wait for C_CLK_SYS_PERIOD;
      assert (tb_master_o.cyc = s_slave.cyc)
        report "Cyc mismatch in master out"
        severity failure;
      assert (tb_master_o.dat = s_slave.dat)
        report "Data mismatch in master out"
        severity failure;
      assert (tb_master_o.adr = s_slave.adr)
        report "Address mismatch in master out"
        severity failure;
      assert (tb_master_o.sel = s_slave.sel)
        report "Sel mismatch in master out"
        severity failure;
      assert (tb_master_o.we  = s_slave.we)
        report "WE mimatch in master out"
        severity failure;
    end loop;
    wait;
  end process;

end tb;

