--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_metadata
--
-- description: Testbench for this little ROM which provides metadata for the 
--              'convention'.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
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
--------------------------------------------------------------------------------

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
--                   Entity declaration for tb_xwb_metadata                  --
--=============================================================================

entity tb_xwb_metadata is
    generic (
        --  Seed of the test
        g_seed       : natural;
        --  The vendor ID.  Official PCI VID are valid.
        --  The default is the CERN PCI VID.
        g_VENDOR_ID  : std_logic_vector(31 downto 0) := x"000010dc";
        --  Device ID, defined by the vendor.
        --  non accurate value given for test
        g_DEVICE_ID  : std_logic_vector(31 downto 0) := x"FFFFFFFF";
        --  Version (semantic version).
        --  non accurate value given for test
        g_VERSION    : std_logic_vector(31 downto 0) := x"00000001";
        --  Capabilities.  Specific to the device.
        --  non accurate value given for test
        g_CAPABILITIES : std_logic_vector(31 downto 0):=x"00000010";
        --  Git commit ID.
        --  non accurate value given for test
        g_COMMIT_ID    : std_logic_vector(127 downto 0) := x"AAAAAAAABBBBBBBB0000001010001010");
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_metadata is

    -- Constants
    constant C_CLK_PERIOD : time := 10 ns;

    -- Signals
    signal tb_clk_i   : std_logic;
    signal tb_rst_n_i : std_logic;
    signal tb_wb_i    : t_wishbone_master_out; 
    signal tb_wb_o    : t_wishbone_master_in;  
    signal stop       : boolean;
    signal s_busy     : std_logic;
    signal s_select   : std_logic_vector(3 downto 0);

begin

    -- Unit Under Test
    UUT : entity work.xwb_metadata
    generic map (
        g_VENDOR_ID    => g_VENDOR_ID,
        g_DEVICE_ID    => g_DEVICE_ID,
        g_VERSION      => g_VERSION,
        g_CAPABILITIES => g_CAPABILITIES,
        g_COMMIT_ID    => g_COMMIT_ID)
    port map(
        clk_i => tb_clk_i,
        rst_n_i => tb_rst_n_i,
        wb_i => tb_wb_i,
        wb_o => tb_wb_o);

    -- Clock generation
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

    -- reset generation
    tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

    -- Stimulus 
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;

    begin
        data.InitSeed(g_SEED);
        report "[STARTING Slave] with seed = " & to_string(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clk_i);
            tb_wb_i.cyc <= data.randSlv(1)(1);
            tb_wb_i.stb <= data.randSlv(1)(1);
            tb_wb_i.we  <= data.randSlv(1)(1);
            tb_wb_i.adr <= data.randSlv(c_wishbone_address_width);
            ncycles := ncycles + 1;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    -- used to describe when the core is busy
    process(tb_clk_i)
    begin
        if rising_edge(tb_clk_i) then
            if tb_rst_n_i = '0' then
                s_busy <= '0';
            else
                s_busy <= '0';
                if (s_busy='0' and tb_wb_i.cyc = '1' and tb_wb_i.stb = '1') then
                    s_busy <= '1';
                    if (s_busy = '1') then
                        assert (tb_wb_o.ack = '1')
                            report "wrong ACK"
                            severity failure;
                    end if;
                end if;
            end if;
        end if;
    end process;

    s_select <= tb_wb_i.adr(5 downto 2) when (tb_wb_i.stb='1' and tb_wb_i.cyc='1' and s_busy='0')
                                        else x"0";
    --------------------------------------------------------------------------------
    --                           Assertions - Self Checking                       --
    --------------------------------------------------------------------------------

    -- The following assertions will ensure that we have the appropriate output data
    -- as it is described in RTL
    process
    begin
        while not stop loop
            wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
            wait until (s_busy = '1');
                case s_select is
                    when x"0" =>wait for C_CLK_PERIOD; 
                                assert (tb_wb_o.dat = g_VENDOR_ID)
                                    report "Data should be VENDOR_ID"
                                    severity failure;

                    when x"1" => assert (tb_wb_o.dat = g_DEVICE_ID)
                                    report "Data should be DEVICE_ID"
                                    severity failure;

                    when x"2" => assert (tb_wb_o.dat = g_VERSION)
                                    report "Data should be VERSION"
                                    severity failure;

                    when x"3" => assert (tb_wb_o.dat = x"FFFE0000")
                                    report "Data should be FFFE0000"
                                    severity failure;

                    when x"4" => assert (tb_wb_o.dat = g_COMMIT_ID(127 downto 96))
                                    report "Data should be COMMIT_ID(127:96)"
                                    severity failure;

                    when x"5" => assert (tb_wb_o.dat = g_COMMIT_ID(95 downto 64))
                                    report "Data should be COMMIT_ID(95 downto 64)"
                                    severity failure;

                    when x"6" => assert (tb_wb_o.dat = g_COMMIT_ID(63 downto 32))
                                    report "Data should be COMMIT_ID(63 downto 32)"
                                    severity failure;

                    when x"7" => assert (tb_wb_o.dat = g_COMMIT_ID(31 downto 0))
                                    report "Data should be COMMIT_ID(31 downto 0)"
                                    severity failure;

                    when x"8" => assert (tb_wb_o.dat = g_CAPABILITIES)
                                    report "Data should be CAPABILITIES"
                                    severity error;

                    when others => assert (tb_wb_o.dat = x"00000000")
                                    report "Data should be 0"
                                    severity error;
                end case;
            end loop;
        wait;
    end process;


end tb;




