--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_remapper
--
-- description: Testbench for a simple Wishbone bus address remapper. Remaps 
-- a certain range of addresses defined by base address and mask to another 
-- base address.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2014-2018
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
--                   Entity declaration for tb_xwb_remapper                  --
--=============================================================================

entity tb_xwb_remapper is
    generic (
        g_seed       : natural;
        g_num_ranges : integer;
        g_base_in    : t_wishbone_address_array(1 downto 0) := (0 => x"47438252",
                                                                1 => x"39BD3DB7");
        g_base_out   : t_wishbone_address_array(1 downto 0) := (0 => x"EEFF0011",
                                                                1 => x"1100FFEE");
        g_mask_in    : t_wishbone_address_array(1 downto 0) := (0 => x"47438252",
                                                                1 => x"39BD3DB7");
        g_mask_out   : t_wishbone_address_array(1 downto 0) := (0 => x"11111111",
                                                                1 => x"00000000"));
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_remapper is

    -- Signals
    signal tb_slave_i  : t_wishbone_slave_in;
    signal tb_slave_o  : t_wishbone_slave_out;
    signal tb_master_i : t_wishbone_master_in;
    signal tb_master_o : t_wishbone_master_out;

    signal stop : boolean;

begin

    -- Unit Under Test
    UUT : entity work.xwb_remapper
    generic map (
        g_num_ranges => g_num_ranges,
        g_base_in    => g_base_in,
        g_base_out   => g_base_out,
        g_mask_in    => g_mask_in,
        g_mask_out   => g_mask_out)
    port map (
        slave_i  => tb_slave_i,
        slave_o  => tb_slave_o,
        master_i => tb_master_i,
        master_o => tb_master_o);

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        report "[STARTING Slave] with seed = " & to_string(g_seed);
        while (NOW < 1 ms) loop
            wait for 10 ns;
            -- slave in
            tb_slave_i.cyc <= data.randSlv(1)(1);
            tb_slave_i.stb <= data.randSlv(1)(1);
            tb_slave_i.adr <= data.randSlv(32);
            tb_slave_i.sel <= data.randSlv(4);
            tb_slave_i.we  <= data.randSlv(1)(1);
            tb_slave_i.dat <= data.randSlv(32);
            -- master in
            tb_master_i.ack   <= data.randSlv(1)(1);
            tb_master_i.err   <= data.randSlv(1)(1);
            tb_master_i.rty   <= data.randSlv(1)(1);
            tb_master_i.stall <= data.randSlv(1)(1);
            tb_master_i.dat   <= data.randSlv(32);
            ncycles        := ncycles + 1;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    --------------------------------------------------------------------------------
    --                                Assertions                                  --
    --------------------------------------------------------------------------------

    process
    begin
        wait for 10 ns;
        assert (tb_master_i = tb_slave_o)
            report "Mismatch between master_i and slave_o"
            severity failure;
        wait;
    end process;

    process
    begin
        wait for 10 ns;
        assert (tb_master_o = tb_slave_i)
            report "Mismatch between master_o and slave_i"
            severity failure;
        wait;
    end process;


end tb;
