--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_shiftreg
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for a generic shift register
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

use work.genram_pkg.all;

--OSVMM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_shiftreg                   --
--=============================================================================

entity tb_gc_shiftreg is
    generic (
        g_seed : natural;
        g_size : integer);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_shiftreg is

  -- constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- signals
  signal tb_clk_i : std_logic;
  signal tb_en_i  : std_logic;
  signal tb_d_i   : std_logic;
  signal tb_q_o   : std_logic;
  signal tb_a_i   : std_logic_vector(f_log2_size(g_size)-1 downto 0);
  signal stop     : boolean;
  signal s_q_o    : std_logic;
  signal s_dat_o  : std_logic_vector(g_size-1 downto 0);

begin

  -- Unit Under Test
  UUT : entity work.gc_shiftreg
  generic map (
    g_size => g_size)
  port map (
    clk_i => tb_clk_i,
    en_i  => tb_en_i,
    d_i   => tb_d_i,
    q_o   => tb_q_o,
    a_i   => tb_a_i);

  -- Clock process
  clk_proc : process
  begin
    while not stop loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_proc;

  --------------------------------------------------------------------------------
  --                                Stimulus                                    --
  --------------------------------------------------------------------------------

  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & integer'image(g_seed);
    while (NOW < 2 ms) loop
      wait until rising_edge(tb_clk_i);
      tb_en_i <= data.randSlv(1)(1);
      tb_d_i  <= data.randSlv(1)(1);
      tb_a_i  <= data.randSlv(f_log2_size(g_size));
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

  -- Geneerate the output data of the testbench
  g_size_big : if (g_size > 32) generate

    process
    begin
      while not stop loop
        wait until rising_edge(tb_clk_i);
        if (tb_en_i = '1') then
          s_dat_o <= s_dat_o(s_dat_o'left - 1 downto 0) & tb_d_i;
        end if;
      end loop;
      wait;
    end process;

    s_q_o <= s_dat_o(to_integer(unsigned(tb_a_i)));

  end generate;

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------

  -- Assure that size is derivative of 64
  assert (g_size >32 AND (g_size mod 64) = 0)
    report "Wrong size" severity failure;


  -- Comparison between RTL and TB output
  process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      assert (s_q_o = tb_q_o)
        report "Data mismatch" severity failure;
    end if;
  end process;


end tb;

