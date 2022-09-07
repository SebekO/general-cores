--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_generic_spram
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- description: Testbench for generic spram
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

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_generic_spram                 --
--=============================================================================

entity tb_generic_spram is
    generic (
        -- Randomization seed generic
        g_seed       : natural;
        -- standard parameters
        g_data_width : natural := 32;
        g_size       : natural := 1024;
        -- if true, the user can write individual bytes by using bwe_i
        g_with_byte_enable : boolean := false;
        -- RAM read-on-write conflict resolution. Can be "read_first" (read-then-write)
        -- or "write_first" (write-then-read)
        g_addr_conflict_resolution : string := "write_first";
        g_init_file                : string := "");
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_generic_spram is

    -- Constants 
    constant C_CLK_PERIOD : time    := 20 ns;
    constant c_NUM_BYTES  : integer := (g_data_width+7)/8;

    -- Signals
    signal tb_rst_n_i : std_logic;
    signal tb_clk_i   : std_logic;
    signal tb_bwe_i   : std_logic_vector((g_data_width+7)/8-1 downto 0) := (others=>'0');
    signal tb_we_i    : std_logic;
    signal tb_a_i     : std_logic_vector(f_log2_size(g_size)-1 downto 0):= (others=>'0');
    signal tb_d_i     : std_logic_vector(g_data_width-1 downto 0)       := (others=>'0');
    signal tb_q_o     : std_logic_vector(g_data_width-1 downto 0);
    signal stop       : boolean;
    signal s_dat_o    : std_logic_vector(g_data_width-1 downto 0);
    signal s_we       : std_logic_vector(c_num_bytes-1 downto 0); 

    type t_ram_type is array(0 to g_size-1) of std_logic_vector(g_data_width-1 downto 0);
    signal s_ram   : t_ram_type;
    signal s_ram_i : std_logic_vector(g_data_width-1 downto 0);
    signal s_ram_o : std_logic_vector(g_data_width-1 downto 0);

begin

    -- Unit Under Test
    UUT : entity work.generic_spram
    generic map (
        g_data_width               => g_data_width,
        g_size                     => g_size,
        g_with_byte_enable         => g_with_byte_enable,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file)
    port map (
        rst_n_i => tb_rst_n_i,
        clk_i   => tb_clk_i, 
        bwe_i   => tb_bwe_i,
        we_i    => tb_we_i,
        a_i     => tb_a_i,
        d_i     => tb_d_i,
        q_o     => tb_q_o);

  -- Clock and reset
  clk_proc : process
  begin
    while not stop loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  tb_rst_n_i <= '0', '1' after 2 * C_CLK_PERIOD;

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        report "[STARTING] with seed = " & integer'image(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clk_i);
            tb_bwe_i <= data.randSlv((g_data_width+7)/8);
            tb_we_i  <= data.randSlv(1)(1);
            tb_a_i   <= data.randSlv(f_log2_size(g_size));
            tb_d_i   <= data.randSlv(g_data_width);
            ncycles  := ncycles + 1;
            wait for C_CLK_PERIOD;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    --------------------------------------------------------------------------------
    --                         Assertions                                         --
    --------------------------------------------------------------------------------

    s_we <= tb_bwe_i when tb_we_i = '1' else (others=>'0');

    gen_with_no_byte_enable_write : if (g_with_byte_enable = FALSE 
                                        AND g_addr_conflict_resolution = "write_first") generate

        process
        begin
          while not stop loop
            wait until (rising_edge(tb_clk_i));
            if (tb_we_i = '1') then
              s_ram(to_integer(unsigned(tb_a_i))) <= tb_d_i;
              s_dat_o                             <= tb_d_i;
              assert (s_dat_o = tb_q_o)
                report "Data mismatch when write enable" severity failure;
            else
              s_dat_o <= s_ram(to_integer(unsigned(tb_a_i)));
              assert (s_dat_o = tb_q_o)
                report "Data mismatch when not write enable" severity failure;
            end if;
          end loop;
          wait;
        end process;

    end generate;                                       

    gen_with_no_byte_enable_read : if (g_with_byte_enable = FALSE 
                                        AND g_addr_conflict_resolution = "read_first") generate

        process
        begin
            while not stop loop
              wait until (rising_edge(tb_clk_i));
              if (tb_we_i = '1') then
                s_ram(to_integer(unsigned(tb_a_i))) <= tb_d_i;
              end if;
              s_dat_o <= s_ram(to_integer(unsigned(tb_a_i)));
              assert (s_dat_o = tb_q_o)
                report "Data mismatch when not write enable" severity failure;
            end loop;
            wait;
        end process;

    end generate;                                       


    gen_with_byte_enable_write : if (g_with_byte_enable = TRUE 
                                        AND g_addr_conflict_resolution = "write_first") generate

        process(s_we, tb_d_i)
        begin
          for i in 0 to C_NUM_BYTES-1 loop
            if s_we(i) = '1' then
              s_ram_i(8*i+7 downto 8*i) <= tb_d_i(8*i+7 downto 8*i);
              s_ram_o(8*i+7 downto 8*i) <= tb_d_i(8*i+7 downto 8*i);
            else
              s_ram_i(8*i+7 downto 8*i) <= s_ram(to_integer(unsigned(tb_a_i)))(8*i+7 downto 8*i);
              s_ram_o(8*i+7 downto 8*i) <= s_ram(to_integer(unsigned(tb_a_i)))(8*i+7 downto 8*i);
            end if;
          end loop;
        end process;

        process
        begin
          while not stop loop
            wait until (rising_edge(tb_clk_i));
              s_ram(to_integer(unsigned(tb_a_i))) <= s_ram_i;
              s_dat_o                             <= s_ram_o;
              assert (s_dat_o = tb_q_o)
                report "Data mismatch when write enable"
                severity failure;
            end loop;
            wait;
        end process;

    end generate;                                       


    gen_with_byte_enable_read : if (g_with_byte_enable = TRUE
                                        AND g_addr_conflict_resolution = "read_first") generate

        process(s_we, tb_d_i)
        begin
          for i in 0 to C_NUM_BYTES-1 loop
            if s_we(i) = '1' then
              s_ram_i(8*i+7 downto 8*i) <= tb_d_i(8*i+7 downto 8*i);
            else
              s_ram_i(8*i+7 downto 8*i) <= s_ram(to_integer(unsigned(tb_a_i)))(8*i+7 downto 8*i);
            end if;
          end loop;
        end process;

        process
        begin
          while not stop loop
            wait until (rising_edge(tb_clk_i));
              s_ram(to_integer(unsigned(tb_a_i))) <= s_ram_i;
              s_dat_o                             <= s_ram(to_integer(unsigned(tb_a_i)));
              assert (s_dat_o = tb_q_o)
                report "Data mismatch when write enable" severity failure;
          end loop;
          wait;
        end process;

    end generate;                                       



end tb;




        


