---------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_generic_dpram_split
--
-- authos:      Konstantinos Blantos
--
-- description: Testbench for generic dpram split core. Develop a 3-D array in
--              order to simulate the RTL behavior and compare the RTL outputs
--              with the outputs from the Testbench.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2017-2018
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

use work.genram_pkg.all;
use work.memory_loader_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_generic_dpram_split           --
--=============================================================================

entity tb_generic_dpram_split is
    generic (
        g_seed                     : natural;
        g_size                     : natural := 16384;
        g_addr_conflict_resolution : string  := "read_first";
        g_init_file                : string  := "";
        g_fail_if_file_not_found   : boolean := true);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_generic_dpram_split is

    constant C_CLK_PERIOD : time := 10 ns;
    constant c_data_width : integer := 32;
    constant c_num_bytes  : integer := (c_data_width+7)/8; --4(?)

    signal tb_rst_n_i : std_logic;
    signal tb_clk_i   : std_logic;
    -- Port A
    signal tb_bwea_i  : std_logic_vector(3 downto 0);
    signal tb_wea_i   : std_logic;
    signal tb_aa_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0);
    signal tb_da_i    : std_logic_vector(31 downto 0);
    signal tb_qa_o    : std_logic_vector(31 downto 0);
    -- Port B
    signal tb_bweb_i  : std_logic_vector(3 downto 0);
    signal tb_web_i   : std_logic;
    signal tb_ab_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0);
    signal tb_db_i    : std_logic_vector(31 downto 0);
    signal tb_qb_o    : std_logic_vector(31 downto 0);
    -- Signals used in testbench
    signal stop       : boolean;
    signal s_dat_a    : std_logic_vector(31 downto 0)            := (others=>'0');
    signal s_dat_b    : std_logic_vector(31 downto 0)            := (others=>'0');
    signal s_we_a     : std_logic_vector(c_num_bytes-1 downto 0) := (others=>'0');
    signal s_we_b     : std_logic_vector(c_num_bytes-1 downto 0) := (others=>'0');
    signal wea_rep    : std_logic_vector(c_num_bytes-1 downto 0) := (others=>'0');
    signal web_rep    : std_logic_vector(c_num_bytes-1 downto 0) := (others=>'0');
    signal s_int_a    : natural;
    signal s_int_b    : natural;
        
    -- Type of the RAM
    type t_split_ram is array(0 to g_size-1) of std_logic_vector(7 downto 0);

    -- Functions
    impure function f_file_to_ramtype(idx : integer) return t_split_ram is
        variable tmp    : t_split_ram;
        variable mem8   : t_ram8_type(0 to g_size-1);
    begin
    -- If no file was given, there is nothing to convert, just return
    if (g_init_file = "" or g_init_file = "none") then
      tmp := (others=>(others=>'0'));
      return tmp;
    end if;

        mem8 := f_load_mem32_from_file_split(g_init_file, g_size, g_fail_if_file_not_found, idx);
        return t_split_ram(mem8);
    end f_file_to_ramtype;

    impure function f_file_contents return t_meminit_array is
    begin
        return f_load_mem_from_file(g_init_file, g_size, c_data_width, g_fail_if_file_not_found);
    end f_file_contents;


    type t_split_ram_array is array(0 to 3) of t_split_ram;
    shared variable s_ram : t_split_ram_array := (f_file_to_ramtype(0),
                                                  f_file_to_ramtype(1),
                                                  f_file_to_ramtype(2),
                                                  f_file_to_ramtype(3));
    

begin
    
    -- Unit Under Test
    UUT : entity work.generic_dpram_split
    generic map (
        g_size                     => g_size,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file,
        g_fail_if_file_not_found   => g_fail_if_file_not_found)
    port map (
        rst_n_i => tb_rst_n_i,
        clk_i   => tb_clk_i,
        bwea_i  => tb_bwea_i,
        wea_i   => tb_wea_i,
        aa_i    => tb_aa_i,
        da_i    => tb_da_i,
        qa_o    => tb_qa_o,
        bweb_i  => tb_bweb_i,
        web_i   => tb_web_i,
        ab_i    => tb_ab_i,
        db_i    => tb_db_i,
        qb_o    => tb_qb_o);

    -- Clock and reset
	  clk_proc : process
	  begin
		  while stop = FALSE loop
			  tb_clk_i <= '1';
			  wait for C_CLK_PERIOD/2;
			  tb_clk_i <= '0';
			  wait for C_CLK_PERIOD/2;
		  end loop;
		  wait;
	  end process clk_proc;

    tb_rst_n_i <= '0', '1' after 2 * C_CLK_PERIOD;

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        report "[STARTING] with seed = " & integer'image(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 0.5 ms) loop
            wait until rising_edge(tb_clk_i);
            tb_bwea_i <= data.randSlv(4);
            tb_wea_i  <= data.randSlv(1)(1);
            tb_aa_i   <= data.randSlv(f_log2_size(g_size));
            tb_da_i   <= data.randSlv(32);
            tb_bweb_i <= data.randSlv(4);
            tb_web_i  <= data.randSlv(1)(1);
            tb_ab_i   <= data.randSlv(f_log2_size(g_size));
            tb_db_i   <= data.randSlv(32);
            ncycles   := ncycles + 1;
            wait for C_CLK_PERIOD;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    --------------------------------------------------------------------------------
    --                          Testbench behavior                                --
    --------------------------------------------------------------------------------

    wea_rep <= (others => tb_wea_i);
    s_we_a  <= tb_bwea_i and wea_rep;
    web_rep <= (others => tb_web_i);
    s_we_b  <= tb_bweb_i and web_rep;

    s_int_a <= f_check_bounds(to_integer(unsigned(tb_aa_i)), 0, g_size-1);
    s_int_b <= f_check_bounds(to_integer(unsigned(tb_ab_i)), 0, g_size-1);

    -- Processes to create two RAMs to store the data
    ram_port_a_and_b : for i in 0 to 3 generate
        
        port_a : process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_I)) then
                s_dat_a((i+1)*8-1 downto i*8) <= s_ram(i)(s_int_a);
                if (s_we_a(i) = '1') then
                    s_ram(i)(s_int_a) := tb_da_i((i+1)*8-1 downto i*8);
                end if;
            end if;
        end process;

    end generate;

    ram_port_b : for j in 0 to 3 generate

        port_b : process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                s_dat_b((j+1)*8-1 downto j*8) <= s_ram(j)(s_int_b);
                if (s_we_b(j) = '1') then
                    s_ram(j)(s_int_b) := tb_db_i((j+1)*8-1 downto j*8);
                end if;
            end if;
        end process;

    end generate;

    --------------------------------------------------------------------------------
    --                          Assertions                                        --
    --------------------------------------------------------------------------------

    -- Compare the testbench's RAM_A with the RTL output for port A
    check_port_a : process(tb_clk_i)
    begin
        if (rising_edge(tb_clk_i)) then
            if (tb_rst_n_i = '1') then
                assert (tb_qa_o = s_dat_a)
                    report "Data mismatch in Port_A" severity failure;
            end if;
        end if;
    end process;
    
    -- Compare the testbench's RAM_B with the RTL output for port B
    check_port_b : process(tb_clk_i)
    begin
        if (rising_edge(tb_clk_i)) then
            if (tb_rst_n_i = '1') then
                assert (tb_qb_o = s_dat_b)
                    report "Data mismatch in Port B" severity failure;
            end if;
        end if;
    end process;

end tb;
