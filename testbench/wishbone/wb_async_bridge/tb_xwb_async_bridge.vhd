------------------------------------------------------------------------------
-- Title      : Testbench for Atmel EBI asynchronous bus <-> Wishbone bridge
-- Project    : White Rabbit Switch
------------------------------------------------------------------------------
-- Author     : Konstantinos Blantos
-- Company    : CERN BE-CEM-EDL
-- Created    : 2022-01-28
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2010 CERN
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

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_xwb_async_bridge              --
--=============================================================================

entity tb_xwb_async_bridge is
    generic (
        g_seed                : natural;
        g_simulation          : integer := 0;
        g_interface_mode      : t_wishbone_interface_mode;
        g_address_granularity : t_wishbone_address_granularity := WORD;
        g_cpu_address_width   : integer := 32);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_async_bridge is

    -- These functions from wb_slave_adapter, are used in 
    -- the self-checking process for the address
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

    function f_zeros(size : integer)
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(0, size));
    end function f_zeros;
    
    -- Constants
    constant C_CLK_SYS_PERIOD : time := 10 ns;

    -- Signals
    signal tb_rst_n_i     : std_logic;
    signal tb_clk_sys_i   : std_logic;
    signal tb_cpu_cs_n_i  : std_logic := '0';
    signal tb_cpu_wr_n_i  : std_logic := '0';
    signal tb_cpu_rd_n_i  : std_logic := '0';
    signal tb_cpu_bs_n_i  : std_logic_vector(3 downto 0) := (others=>'0');
    signal tb_cpu_addr_i  : std_logic_vector(g_cpu_address_width-1 downto 0) := (others=>'0');
    signal tb_cpu_data_b  : std_logic_vector(31 downto 0);
    signal tb_cpu_nwait_o : std_logic;
    signal tb_master_o    : t_wishbone_master_out;
    signal tb_master_i    : t_wishbone_master_in;
    signal stop           : boolean;
    signal s_wr_pulse     : std_logic;
    signal s_rd_pulse     : std_logic;
    signal s_cs_synced    : std_logic;
    signal s_addr_o       : std_logic_vector(g_cpu_address_width-1 downto 0) := (others=>'0');
    signal s_busy         : std_logic;
    signal s_data_o       : std_logic_vector(31 downto 0);

begin

    -- Unit Under Test
    UUT : entity work.xwb_async_bridge
    generic map (
        g_simulation          => g_simulation,
        g_interface_mode      => g_interface_mode,
        g_address_granularity => g_address_granularity,
        g_cpu_address_width   => g_cpu_address_width)
    port map (
        rst_n_i     => tb_rst_n_i, 
        clk_sys_i   => tb_clk_sys_i,
        cpu_cs_n_i  => tb_cpu_cs_n_i,
        cpu_wr_n_i  => tb_cpu_wr_n_i,
        cpu_rd_n_i  => tb_cpu_rd_n_i,
        cpu_bs_n_i  => tb_cpu_bs_n_i,
        cpu_addr_i  => tb_cpu_addr_i,
        cpu_data_b  => tb_cpu_data_b,
        cpu_nwait_o => tb_cpu_nwait_o,
        master_o    => tb_master_o,
        master_i    => tb_master_i);

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
    end process;
 
    -- reset generation
    tb_rst_n_i <= '0', '1' after 2*C_CLK_SYS_PERIOD;

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        report "[STARTING Slave] with seed = " & to_string(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clk_sys_i);
            tb_cpu_cs_n_i     <= data.randSlv(1)(1);
            tb_cpu_wr_n_i     <= data.randSlv(1)(1);
            tb_cpu_rd_n_i     <= data.randSlv(1)(1);
            tb_cpu_bs_n_i     <= data.randSlv(4);
            tb_cpu_addr_i     <= data.randSlv(g_cpu_address_width);
            tb_master_i.ack   <= data.randSlv(1)(1);
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

    g_simulation_on : if (g_simulation = 1) generate
        s_wr_pulse <= not tb_cpu_wr_n_i;
        s_rd_pulse <= not tb_cpu_rd_n_i;
        s_cs_synced<= tb_cpu_cs_n_i;
    end generate;

    -- the address signals have one clock delay
    addr_self_check : process(tb_clk_sys_i)
    begin
        if (rising_edge(tb_clk_sys_i)) then
            if (tb_rst_n_i = '1') then
                if (s_cs_synced='0') then
                    if (g_address_granularity = WORD) then
                        s_addr_o <= tb_cpu_addr_i;
                        assert (tb_master_o.adr = s_addr_o)
                            report "Address mismatch when WORD granularity"
                            severity failure;
                    elsif (g_address_granularity = BYTE) then
                        s_addr_o <= tb_cpu_addr_i(c_wishbone_address_width-f_num_byte_address_bits-1 downto 0)& f_zeros(f_num_byte_address_bits);
                        assert (tb_master_o.adr = s_addr_o) 
                            report "Address mismatch when BYTE granularity"
                            severity failure;
                    else
                        s_addr_o <=  f_zeros(f_num_byte_address_bits) & tb_cpu_addr_i(c_wishbone_address_width-1 downto f_num_byte_address_bits); 
                        assert (tb_master_o.adr = s_addr_o)
                                report "Address mismatch"
                                severity failure;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(tb_clk_sys_i)
    begin
        if(rising_edge(tb_clk_sys_i)) then
            if(tb_rst_n_i = '0') then
                s_busy <= '0';
                s_data_o <= (others=>'0');
            else
                if(s_cs_synced = '0') then
                    if(s_busy = '1') then
                        if(tb_master_i.ack = '1') then
                            s_busy <= '0';
                        end if;
                    elsif(s_rd_pulse = '1' or s_wr_pulse = '1') then
                        if(s_wr_pulse = '1') then
                            s_data_o <= tb_cpu_data_b;
                            assert (tb_master_o.dat = s_data_o)
                                report "Data mismatch"
                                severity failure;
                        end if;
                        s_busy <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
         

end tb;

 


