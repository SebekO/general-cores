-------------------------------------------------------------------------------
-- Title      : Testbench for WhiteRabbit PTP Core tics wrapper
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : tb_xwb_tics.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN
-- Created    : 2022-01-26
-- Last update: 
-- Platform   : FPGA-generics
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2011-2013 CERN
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
--                   Entity declaration for tb_xwb_tics                      --
--=============================================================================

entity tb_xwb_tics is
    generic (
        g_seed                : natural;
        g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
        g_address_granularity : t_wishbone_address_granularity := WORD;
        g_period              : integer := 10);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_tics is

    constant C_CLK_PERIOD : time := 10 ns;

    signal tb_clk_sys_i : std_logic;
    signal tb_rst_n_i   : std_logic;
    signal tb_slave_i   : t_wishbone_slave_in;
    signal tb_slave_o   : t_wishbone_slave_out;
    signal tb_desc_o    : t_wishbone_device_descriptor;

    signal stop           : boolean;
    signal s_cnt_div      : unsigned(f_ceil_log2(g_period)-1 downto 0);
    signal s_cnt_overflow : std_logic;
    signal s_data_o       : std_logic_vector(31 downto 0);

begin

    -- Unit Under Test
    UUT : entity work.xwb_tics
    generic map (
        g_interface_mode      => g_interface_mode,
        g_address_granularity => g_address_granularity,
        g_period              => g_period)
    port map (
        clk_sys_i => tb_clk_sys_i,
        rst_n_i   => tb_rst_n_i,
        slave_i   => tb_slave_i,
        slave_o   => tb_slave_o,
        desc_o    => open); 

        -- Clock generation
	clk_proc : process
	begin
		while STOP = FALSE loop
			tb_clk_sys_i <= '1';
			wait for C_CLK_PERIOD/2;
			tb_clk_sys_i <= '0';
			wait for C_CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_proc;

    -- reset generation
    tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

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
            tb_slave_i.cyc <= data.randSlv(1)(1);
            tb_slave_i.we  <= data.randSlv(1)(1);
            tb_slave_i.stb <= data.randSlv(1)(1);
            tb_slave_i.sel <= data.randSlv(4);
            tb_slave_i.adr <= data.randSlv(c_wishbone_data_width);
            tb_slave_i.dat <= data.randSlv(c_wishbone_address_width);
            ncycles := ncycles + 1;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    --------------------------------------------------------------------------------
    --                                Assertions                                  --
    --------------------------------------------------------------------------------

    -- Used to regenerate the cnt_overflow
    process(tb_clk_sys_i)
    begin
        if rising_edge(tb_clk_sys_i) then
            if(tb_rst_n_i = '0') then
                s_cnt_div      <= (others => '0');
                s_cnt_overflow <= '0';
            else
                if(s_cnt_div = g_period-1) then
                    s_cnt_div      <= (others => '0');
                    s_cnt_overflow <= '1';
                else
                    s_cnt_div      <= s_cnt_div + 1;
                    s_cnt_overflow <= '0';
                end if;
            end if;
        end if;
    end process;

    -- used to describe the output's behavior
    data_o : process(tb_clk_sys_i)
    begin
        if (rising_edge(tb_clk_sys_i)) then
            if (tb_rst_n_i = '0') then
                s_data_o <= (others=>'0');
            else
                if (s_cnt_overflow = '1') then
                    s_data_o <= tb_slave_o.dat;
                else
                    s_data_o <= s_data_o;
                end if;
            end if;
        end if;
    end process;

    -- self-checking process to check the output
    output_check : process
    begin
        while (stop = FALSE) loop
            wait until falling_edge(s_cnt_overflow);
            wait for C_CLK_PERIOD;
            assert (unsigned(tb_slave_o.dat) - unsigned(s_data_o) = 1) 
                report "Difference is not 1"
                severity error;
        end loop;
        wait;
    end process output_check;

end tb;


