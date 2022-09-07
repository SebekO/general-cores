------------------------------------------------------------------------------
-- Title      : Testbench for wishbone skidpad
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_wb_skidpad.vhd
-- Company    : CERN (BE-CEM-EDL)
-- Platform   : FPGA-generics
-- Standard   : VHDL '08
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CERN
--
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the "License") (which enables you, at your option,
-- to treat this file as licensed under the Apache License 2.0); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://solderpad.org/licenses/SHL-0.51.
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

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_wb_skidpad                    --
--=============================================================================

entity tb_wb_skidpad is
  generic (
    g_seed    : natural;
    g_adrbits : natural := 32);
end entity;

architecture tb of tb_wb_skidpad is

  -- Constant
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_push_i  : std_logic := '0';
  signal tb_pop_i   : std_logic := '0';
  signal tb_full_o  : std_logic;
  signal tb_empty_o : std_logic;
  signal tb_adr_i   : std_logic_vector(g_adrbits-1 downto 0);
  signal tb_dat_i   : std_logic_vector(32-1 downto 0);
  signal tb_sel_i   : std_logic_vector(4-1 downto 0);
  signal tb_we_i    : std_logic := '0';
  signal tb_adr_o   : std_logic_vector(g_adrbits-1 downto 0);
  signal tb_dat_o   : std_logic_vector(32-1 downto 0);
  signal tb_sel_o   : std_logic_vector(4-1 downto 0);
  signal tb_we_o    : std_logic;

  signal stop       : boolean;
  signal s_buffer0  : std_logic_vector(g_adrbits+37-1 downto 0);
  signal s_buffer1  : std_logic_vector(g_adrbits+37-1 downto 0);
  signal s_buffer2  : std_logic_vector(g_adrbits+37-1 downto 0);
  signal s_buffer   : std_logic_vector(g_adrbits+37-1 downto 0);
  signal r_full0    : std_logic := '0';
  signal r_full1    : std_logic := '0';
  signal s_valid    : std_logic := '0';

begin

  -- Unit Under Test
  UUT : entity work.wb_skidpad
  generic map (
    g_adrbits => g_adrbits)
  port map (
    clk_i     => tb_clk_i,   
    rst_n_i   => tb_rst_n_i, 
    push_i    => tb_push_i, 
    pop_i     => tb_pop_i, 
    full_o    => tb_full_o,
    empty_o   => tb_empty_o, 
    adr_i     => tb_adr_i, 
    dat_i     => tb_dat_i,
    sel_i     => tb_sel_i,
    we_i      => tb_we_i,
    adr_o     => tb_adr_o, 
    dat_o     => tb_dat_o, 
    sel_o     => tb_sel_o, 
    we_o      => tb_we_o);

  -- Clock generation
  clk_proc : process
  begin
    while stop = FALSE loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    wait until tb_rst_n_i = '1';
    while (NOW < 4 ms) loop
      wait until rising_edge(tb_clk_i);
      tb_push_i <= data.randSlv(1)(1);
      tb_pop_i  <= data.randSlv(1)(1);
      tb_adr_i  <= data.randSlv(g_adrbits);
      tb_dat_i  <= data.randSlv(32);
      tb_sel_i  <= data.randSlv(4);
      tb_we_i   <= data.randSlv(1)(1);
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------
  
  -- valid signal  
  s_valid <= r_full1 or r_full0;
 
  -- full flags needed
  full_sig : process(tb_clk_i, tb_rst_n_i)
  begin
      if tb_rst_n_i = '0' then
        r_full0 <= '0';
        r_full1 <= '0';
      elsif rising_edge(tb_clk_i) then
        r_full0 <= tb_push_i or tb_full_o;
        r_full1 <= not tb_pop_i and s_valid;
      end if;
  end process;

  -- Used to store the input data in one vector
  buffer_o : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if (tb_full_o = '0') then
        s_buffer0 <= tb_adr_i & tb_dat_i & tb_sel_i & tb_we_i;
      end if;
      if (r_full1 = '0') then
        s_buffer1 <= s_buffer0;
      end if;
    end if;
  end process;

  -- used to create the same delay as in the RTL
  s_buffer2 <= s_buffer1 when r_full1='1' else s_buffer0;
  s_buffer  <= s_buffer2;
  
  -- Output checking assertions
  check : process
  begin
    while not stop loop
      wait until rising_edge(tb_clk_i);
        assert (s_buffer(37+g_adrbits-1 downto 37) = tb_adr_o) 
          report "Address mismatch" severity error;
        assert (s_buffer(36 downto 5) = tb_dat_o)
          report "Data mismatch" severity error;
        assert (s_buffer(4 downto 1) = tb_sel_o)
          report "Select mismatch" severity error;
        assert (s_buffer(0) = tb_we_o)
          report "Write Enable mismatch" severity error;
    end loop;
    wait;
  end process;

end tb;
