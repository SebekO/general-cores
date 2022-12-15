--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_generic_dpram_dualclock
--
-- description: Testbench for a true dual-port synchronous RAM for Xilinx FPGAs
--              with:
--                  - configurable address and data bus width
--                  - byte-addressing mode (data bus width restricted to
--                    multiple of 8 bits)
--
--------------------------------------------------------------------------------
-- Copyright CERN 2011-2018
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

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_generic_dpram_dualclock                   --
--=================================================================================================

entity tb_generic_dpram_dualclock is
    generic (
        g_seed_a                   : natural;
        g_seed_b                   : natural;
        g_data_width               : natural := 32;
        g_size                     : natural := 16384;
        g_with_byte_enable         : boolean := false;
        g_addr_conflict_resolution : string  := "read_first";
        g_init_file                : string  := "";
        g_fail_if_file_not_found   : boolean := true);
end entity;

--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_generic_dpram_dualclock is

    -- constants
    constant C_CLKA_PERIOD : time := 10 ns;
    constant C_CLKB_PERIOD : time := 8 ns;
    constant c_num_bytes : integer := (g_data_width+7)/8;

    -- types
    type t_ram_type is array(0 to g_size-1) of std_logic_vector(g_data_width-1 downto 0);

    -- functions
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

    function f_is_synthesis return boolean is
    begin
        -- synthesis translate_off
        return false;
        -- synthesis translate_on
        return true;
    end f_is_synthesis;

    -- signals
    signal tb_rst_n_i : std_logic := '1';
    signal tb_clka_i  : std_logic;
    signal tb_bwea_i  : std_logic_vector((g_data_width+7)/8-1 downto 0);
    signal tb_wea_i   : std_logic;
    signal tb_aa_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0);
    signal tb_da_i    : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
    signal tb_qa_o    : std_logic_vector(g_data_width-1 downto 0);
    signal tb_clkb_i  : std_logic;
    signal tb_bweb_i  : std_logic_vector((g_data_width+7)/8-1 downto 0);
    signal tb_web_i   : std_logic;
    signal tb_ab_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0);
    signal tb_db_i    : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
    signal tb_qb_o    : std_logic_vector(g_data_width-1 downto 0);

    signal stop       : boolean;
    signal s_tb_we_a  : std_logic_vector(c_num_bytes-1 downto 0);
    signal s_tb_we_b  : std_logic_vector(c_num_bytes-1 downto 0);
    signal s_wea_rep  : std_logic_vector(c_num_bytes-1 downto 0);
    signal s_web_rep  : std_logic_vector(c_num_bytes-1 downto 0);
    signal s_dat_a    : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');
    signal s_dat_b    : std_logic_vector(g_data_width-1 downto 0) := (others=>'0');

    shared variable s_ram : t_ram_type := f_file_to_ramtype;

begin

    --Unit Under Test
    UUT : entity work.generic_dpram_dualclock
    generic map (
        g_data_width               => g_data_width,
        g_size                     => g_size,
        g_with_byte_enable         => g_with_byte_enable,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file,
        g_fail_if_file_not_found   => g_fail_if_file_not_found)
    port map (
        rst_n_i => tb_rst_n_i,
        clka_i  => tb_clka_i,
        bwea_i  => tb_bwea_i,
        wea_i   => tb_wea_i,
        aa_i    => tb_aa_i,
        da_i    => tb_da_i,
        qa_o    => tb_qa_o,
        clkb_i  => tb_clkb_i,
        bweb_i  => tb_bweb_i,
        web_i   => tb_web_i,
        ab_i    => tb_ab_i,
        db_i    => tb_db_i,
        qb_o    => tb_qb_o);


    -- Clocks and reset generation
  clka_proc : process
  begin
    while stop = FALSE loop
      tb_clka_i <= '1';
      wait for C_CLKA_PERIOD/2;
      tb_clka_i <= '0';
      wait for C_CLKA_PERIOD/2;
    end loop;
    wait;
  end process clka_proc;

  clkb_proc : process
  begin
    while stop = FALSE loop
      tb_clkb_i <= '1';
      wait for C_CLKB_PERIOD/2;
      tb_clkb_i <= '0';
      wait for C_CLKB_PERIOD/2;
    end loop;
    wait;
  end process clkb_proc;

    tb_rst_n_i <= '0', '1' after 30 ns;

    --------------------------------------------------------------------------------
    --                                Stimulus                                    --
    --------------------------------------------------------------------------------

    stim_a : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed_a);
        report "[STARTING - A] with seed = " & integer'image(g_seed_a);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clka_i);
            tb_bwea_i <= data.randSlv((g_data_width+7)/8);
            tb_wea_i  <= data.randSlv(1)(1);
            tb_aa_i   <= data.randSlv(f_log2_size(g_size));
            tb_da_i   <= data.randSlv(g_data_width);
            ncycles   := ncycles + 1;
            wait for C_CLKA_PERIOD;
        end loop;
        report "[A] Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim_a;

    stim_b : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed_b);
        report "[STARTING - B] with seed = " & integer'image(g_seed_b);
        wait until tb_rst_n_i = '1';
        while (stop = FALSE) loop
            wait until rising_edge(tb_clkb_i);
            tb_bweb_i <= data.randSlv((g_data_width+7)/8);
            tb_web_i  <= data.randSlv(1)(1);
            tb_ab_i   <= data.randSlv(f_log2_size(g_size));
            tb_db_i   <= data.randSlv(g_data_width);
            ncycles   := ncycles + 1;
            wait for C_CLKB_PERIOD;
        end loop;
        report "[B] Number of simulation cycles = " & to_string(ncycles);
        wait;
    end process stim_b;



    s_wea_rep <= (others => tb_wea_i);
    s_web_rep <= (others => tb_web_i);
    s_tb_we_a <= tb_bwea_i and s_wea_rep;
    s_tb_we_b <= tb_bweb_i and s_web_rep;

    --------------------------------------------------------------------------------
    -- Test case 1 : Byte enable & dont care/Rd first in addr conflict resolution --
    --------------------------------------------------------------------------------

    g_with_byte_enable_read_first : if (g_with_byte_enable = TRUE
                           AND (g_addr_conflict_resolution = "dont_care"
                              OR g_addr_conflict_resolution = "read_first")) generate

        process (tb_clka_i)
        begin
            if rising_edge(tb_clka_i) then
                if f_is_synthesis then
                    s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
                else
                    s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)) mod g_size);
                end if;
                for i in 0 to c_num_bytes-1 loop
                    if s_tb_we_a(i) = '1' then
                        s_ram(to_integer(unsigned(tb_aa_i)))((i+1)*8-1 downto i*8) := tb_da_i((i+1)*8-1 downto i*8);
                    end if;
                end loop;
            end if;
        end process;


        process (tb_clkb_i)
        begin
            if rising_edge(tb_clkb_i) then
                if f_is_synthesis then
                    s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
                else
                    s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)) mod g_size);
                end if;
                for i in 0 to c_num_bytes-1 loop
                    if s_tb_we_b(i) = '1' then
                        s_ram(to_integer(unsigned(tb_ab_i)))((i+1)*8-1 downto i*8) := tb_db_i((i+1)*8-1 downto i*8);
                    end if;
                end loop;
            end if;
        end process;

    end generate;

    --------------------------------------------------------------------------------
    -- Test case 2 : No byte enable, dont care/Rd first in addr conflict resolution --
    --------------------------------------------------------------------------------

    g_no_byte_enable_read_first : if (g_with_byte_enable = FALSE
                              AND (g_addr_conflict_resolution = "read_first"
                                OR g_addr_conflict_resolution = "dont_care")) generate

        port_a : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clka_i) and tb_rst_n_i = '1';
                s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
                if (tb_wea_i = '1') then
                    s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i;
                end if;
            end loop;
            wait;
        end process;

        port_b : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clkb_i) and tb_rst_n_i = '1';
                s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
                if (tb_web_i = '1') then
                    s_ram(to_integer(unsigned(tb_ab_i))) := tb_db_i;
                end if;
            end loop;
            wait;
        end process;

    end generate;

    --------------------------------------------------------------------------------
    -- Test case 3 : No byte enable & Write first in addr conflict resolution     --
    --------------------------------------------------------------------------------

    g_no_byte_enable_write_first : if (g_with_byte_enable = FALSE
                            AND g_addr_conflict_resolution = "write_first") generate

        port_a : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clka_i) and tb_rst_n_i = '1';
                if (tb_wea_i = '1') then
                    s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i;
                    s_dat_a <= tb_da_i;
                else
                    s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
                end if;
            end loop;
            wait;
        end process;

        port_b : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clkb_i) and tb_rst_n_i = '1';
                if (tb_web_i = '1') then
                    s_ram(to_integer(unsigned(tb_ab_i))) := tb_db_i;
                    s_dat_b <= tb_db_i;
                else
                    s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
                end if;
            end loop;
            wait;
        end process;

    end generate;

    --------------------------------------------------------------------------------
    -- Test case 4 : No byte enable & no change in addr conflict resolution       --
    --------------------------------------------------------------------------------

    g_no_byte_enable_write_no_change : if (g_with_byte_enable = FALSE
                            AND g_addr_conflict_resolution = "no_change") generate

        port_a : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clka_i) and tb_rst_n_i = '1';
                if (tb_wea_i = '1') then
                    s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i;
                else
                    s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
                end if;
            end loop;
            wait;
        end process;

        port_b : process
        begin
            while (stop = FALSE) loop
                wait until rising_edge(tb_clkb_i) and tb_rst_n_i = '1';
                if (tb_web_i = '1') then
                    s_ram(to_integer(unsigned(tb_ab_i))) := tb_db_i;
                else
                    s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
                end if;
            end loop;
            wait;
        end process;

    end generate;

    --------------------------------------------------------------------------------
    --                              Assertions                                    --
    --------------------------------------------------------------------------------

    -- Compare the testbench's RAM_A with the RTL output for port A
    check_port_a : process(tb_clka_i)
    begin
        if (rising_edge(tb_clka_i)) then
            if (tb_rst_n_i = '1') then
                assert (tb_qa_o = s_dat_a)
                    report "Data mismatch in Port_A" severity failure;
            end if;
        end if;
    end process;

    -- Compare the testbench's RAM_B with the RTL output for port B
    check_port_b : process(tb_clkb_i)
    begin
        if (rising_edge(tb_clkb_i)) then
            if (tb_rst_n_i = '1') then
                assert (tb_qb_o = s_dat_b)
                    report "Data mismatch in Port B" severity failure;
            end if;
        end if;
    end process;


end tb;
