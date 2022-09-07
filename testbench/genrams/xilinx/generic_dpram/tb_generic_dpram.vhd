--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_generic_dpram
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for a true dual-port synchronous RAM for Xilinx FPGAs with:
-- - configurable address and data bus width
-- - byte-addressing mode (data bus width restricted to multiple of 8 bits)
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

use work.genram_pkg.all;
use work.memory_loader_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_generic_dpram
--=================================================================================================

entity tb_generic_dpram is
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

architecture tb of tb_generic_dpram is

  --------------------------------------------------------------------------------
  --                            Constants                                       --
  --------------------------------------------------------------------------------

  constant C_CLKA_PERIOD : time   := 10 ns;
  constant C_CLKB_PERIOD : time   := 8 ns;
  constant c_gen_split   :boolean := (g_dual_clock = false and g_data_width=32 and
      g_with_byte_enable=true and (g_addr_conflict_resolution="dont_care" or
      g_addr_conflict_resolution="read_first"));
  constant c_gen_sc      :boolean := (not c_gen_split) and (not g_dual_clock);
  constant c_gen_dc      :boolean := g_dual_clock;
  constant c_num_bytes   :integer := (g_data_width+7)/8;
  
  --------------------------------------------------------------------------------------
  --                                    Types                                         --
  --------------------------------------------------------------------------------------

  type t_ram_type is array(0 to g_size-1) of std_logic_vector(g_data_width-1 downto 0);
  type t_split_ram is array(0 to g_size-1) of std_logic_vector(7 downto 0);
  type t_split_ram_array is array(0 to 3) of t_split_ram;


  --------------------------------------------------------------------------------
  --                            Functions                                       --
  --------------------------------------------------------------------------------
  function f_is_synthesis return boolean is
  begin
    -- synthesis translate_off
    return false;
    -- synthesis translate_on
    return true;
  end f_is_synthesis;
  
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
    return f_load_mem_from_file(g_init_file, g_size, g_data_width, g_fail_if_file_not_found);
  end f_file_contents;


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

  --------------------------------------------------------------------------------------
  --                                    Signals                                       --
  --------------------------------------------------------------------------------------

  signal tb_rst_n_i : std_logic := '1';
  -- Port A
  signal tb_clka_i  : std_logic;
  signal tb_bwea_i  : std_logic_vector((g_data_width+7)/8-1 downto 0)  := (others=>'0');
  signal tb_wea_i   : std_logic;
  signal tb_aa_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal tb_da_i    : std_logic_vector(g_data_width-1 downto 0)        := (others=>'0');
  signal tb_qa_o    : std_logic_vector(g_data_width-1 downto 0);
  -- Port B
  signal tb_clkb_i  : std_logic;
  signal tb_bweb_i  : std_logic_vector((g_data_width+7)/8-1 downto 0)  := (others=>'0');
  signal tb_web_i   : std_logic;
  signal tb_ab_i    : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal tb_db_i    : std_logic_vector(g_data_width-1 downto 0)        := (others=>'0');
  signal tb_qb_o    : std_logic_vector(g_data_width-1 downto 0);
    
  signal stop       : boolean;
  signal s_dat_a    : std_logic_vector(g_data_width-1 downto 0); 
  signal s_dat_b    : std_logic_vector(g_data_width-1 downto 0);
  signal s_we_a     : std_logic_vector(c_num_bytes-1 downto 0);
  signal s_we_b     : std_logic_vector(c_num_bytes-1 downto 0);
  signal wea_rep, web_rep : std_logic_vector(c_num_bytes-1 downto 0);
  signal s_int_a    : natural;
  signal s_int_b    : natural;

  shared variable s_ram       : t_ram_type := f_file_to_ramtype;
  shared variable s_split_ram : t_split_ram_array := (f_file_to_ramtype(0),
                                                      f_file_to_ramtype(1),
                                                      f_file_to_ramtype(2),
                                                      f_file_to_ramtype(3));

begin

  -- Unit Under Test
  UUT : entity work.generic_dpram
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
    qa_o    => tb_qa_o, 
    clkb_i  => tb_clkb_i,
    bweb_i  => tb_bweb_i, 
    web_i   => tb_web_i,
    ab_i    => tb_ab_i, 
    db_i    => tb_db_i, 
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
      tb_bweb_i <= data.randSlv((g_data_width+7)/8) when tb_web_i = '1';
      tb_web_i  <= data.randSlv(1)(1);
      tb_ab_i   <= data.randSlv(f_log2_size(g_size)) when tb_web_i = '1';
      tb_db_i   <= data.randSlv(g_data_width);
      ncycles   := ncycles + 1;
      wait for C_CLKB_PERIOD;
    end loop;
    report "[B] Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process stim_b;

  --------------------------------------------------------------------------------
  --                  Testbench behavior for the test cases                     --
  --------------------------------------------------------------------------------

  -- There are three different ways of using this generic dpram. 
  -- They are: dual clock, single clock and splitram. The behavior of these 3
  -- approaches presented below, which behavior is similar to the RTL's behavior


  -- Dual clock approach with no byte enable
  gen_dual_clock_byte_false : if (c_gen_dc and g_with_byte_enable = false) generate

    -- Simulate the ram for A
    process(tb_clka_i)
    begin
      if rising_edge(tb_clka_i) then
        s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
        if tb_wea_i then
          s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i;
        end if;
      end if;
    end process;

    -- Simulate the ram for B
    process(tb_clkb_i)
    begin
      if rising_edge(tb_clkb_i) then
        s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
        if tb_web_i then
          s_ram(to_integer(unsigned(tb_ab_i))) := tb_db_i;
        end if;
      end if;
    end process;

  end generate;


  -- Dual clock approach with byte enable
  gen_dual_clock_byte_true : if (c_gen_dc and g_with_byte_enable = true) generate
    
    wea_rep <= (others => tb_wea_i);
    web_rep <= (others => tb_web_i);

    s_we_a <= tb_bwea_i and wea_rep;
    s_we_b <= tb_bweb_i and web_rep;
    
    -- Behavior like in the RTL for port A
    process (tb_clka_i)
    begin
      if rising_edge(tb_clka_i) then
        if f_is_synthesis then
          s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
        else
          s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)) mod g_size);
        end if;
        for i in 0 to c_num_bytes-1 loop
          if s_we_a(i) = '1' then
            s_ram(to_integer(unsigned(tb_aa_i)))((i+1)*8-1 downto i*8) := tb_da_i((i+1)*8-1 downto i*8);
          end if;
        end loop;
      end if;
    end process;

    -- Behavior like in the RTL for port B
    process (tb_clkb_i)
    begin
      if rising_edge(tb_clkb_i) then
        if f_is_synthesis then
          s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
        else
          s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)) mod g_size);
        end if;
        for i in 0 to c_num_bytes-1 loop
          if s_we_b(i) = '1' then
            s_ram(to_integer(unsigned(tb_ab_i)))((i+1)*8-1 downto i*8)
              := tb_db_i((i+1)*8-1 downto i*8);
          end if;
        end loop;
      end if;
    end process;
    
  end generate;


  -- Split ram approach
  gen_split : if c_gen_split generate

    wea_rep <= (others => tb_wea_i);
    web_rep <= (others => tb_web_i);

    s_we_a <= tb_bwea_i and wea_rep;
    s_we_b <= tb_bweb_i and web_rep;
 
    s_int_a <= f_check_bounds(to_integer(unsigned(tb_aa_i)), 0, g_size-1);
    s_int_b <= f_check_bounds(to_integer(unsigned(tb_ab_i)), 0, g_size-1);

    -- Processes to create two RAMs to store the data
    ram_port_a_and_b : for i in 0 to 3 generate
        
        port_a : process(tb_clka_i)
        begin
            if rising_edge(tb_clka_i) then
                s_dat_a((i+1)*8-1 downto i*8) <= s_split_ram(i)(s_int_a);
                if s_we_a(i) = '1' then
                    s_split_ram(i)(s_int_a) := tb_da_i((i+1)*8-1 downto i*8);
                end if;
            end if;
        end process;

    end generate;

    ram_port_b : for j in 0 to 3 generate

        port_b : process(tb_clka_i)
        begin
            if rising_edge(tb_clka_i) then
                s_dat_b((j+1)*8-1 downto j*8) <= s_split_ram(j)(s_int_b);
                if s_we_b(j) = '1' then
                    s_split_ram(j)(s_int_b) := tb_db_i((j+1)*8-1 downto j*8);
                end if;
            end if;
        end process;

    end generate;

  end generate;

  
  -- Single clock approach with no byte enable 
  gen_single_clk_no_byte_enable : if (c_gen_sc and not g_with_byte_enable) generate

    port_A: process(tb_clka_i)
    begin
      if rising_edge(tb_clka_i) then
        if f_is_synthesis then
          s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)));
        else
          s_dat_a <= s_ram(to_integer(unsigned(tb_aa_i)) mod g_size);
        end if;
        if(tb_wea_i = '1') then
          s_ram(to_integer(unsigned(tb_aa_i))) := tb_da_i;
        end if;
      end if;
    end process;

    port_B: process(tb_clka_i)
    begin
      if rising_edge(tb_clka_i) then
        if f_is_synthesis then
          s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)));
        else
          s_dat_b <= s_ram(to_integer(unsigned(tb_ab_i)) mod g_size);
        end if;
        if(tb_web_i = '1') then
          s_ram(to_integer(unsigned(tb_ab_i))) := tb_db_i;
        end if;
      end if;
    end process;

  end generate;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  -- No matter what approach is being tested, the output of the RTL should be
  -- the same with the one from the testbench in order to be sure that the 
  -- behavior of both are the correct

  -- Port A
  check_out_data_a : process
  begin
    while not stop loop
    wait until rising_edge(tb_clka_i);
      if tb_wea_i then
        wait for C_CLKA_PERIOD;
        assert (s_dat_a = tb_qa_o)
          report "PORT A: Data mismatch" severity error;
      end if;
    end loop;
    wait;
  end process;

  -- PORT B
  check_out_data_b : process
  begin
    while not stop loop
    wait until rising_edge(tb_clkb_i);
      if tb_web_i then
        wait for C_CLKB_PERIOD;
        assert (s_dat_b = tb_qb_o)
          report "PORT B: Data mismatch" severity error;
      end if;
    end loop;
    wait;
  end process;


end tb;
