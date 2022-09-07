--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_glitch_filt
--
-- author : Konstantinos Blantos
--
-- description: Testbench for: Glitch filter with selectable length, consisting 
-- of a set of chained flip-flops followed by a comparator. The comparator 
-- toggles to '1' when all FFs in the chain are '1' and respectively to '0' 
-- when all the FFS in the chain are '0'.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2013-2018
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

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_gc_glitch_filt                --
--=============================================================================

entity tb_gc_glitch_filt is 
  generic (
    g_seed : natural;
    g_len  : natural := 0);
end entity;


--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_glitch_filt is

  -- Constants  
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_n_i : std_logic;
  signal tb_dat_i   : std_logic := '0';
  signal tb_dat_o   : std_logic;
  signal stop : boolean := FALSE;
  signal s_glitch_filt : std_logic_vector(g_len downto 0) := (others=>'0');

  -- Shared variables, used for coverage
  shared variable cp_rst_n_i    : covPType;
  shared variable cp_dat_o_high : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_glitch_filt
  generic map (
    g_len   => g_len)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_n_i,
    dat_i   => tb_dat_i,
    dat_o   => tb_dat_o);

  -- Clock generation
  clk_i_process : process
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
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_dat_i <= data.randSlv(1)(1);
      ncycles  := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    report "Test PASS!";
    stop <= TRUE;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                           Assertions - Self Checking                       --
  --------------------------------------------------------------------------------

  -- Output should be like input after one clock delay
  -- when length is zero
  g_len_zero : if (g_len = 0) generate
    process(tb_clk_i)
    begin
      if (rising_edge(tb_clk_i) and tb_rst_n_i = '1') then
        if falling_edge(tb_dat_i) then
          assert (tb_dat_i = tb_dat_o)
            report "Data mismatch" severity failure;
        end if;
      end if;
    end process;
  end generate;

  -- Generate glitch filter FF's when length of filter is > 0    
  g_len_non_zero : if (g_len > 0) generate
    process(tb_clk_i)
    begin
      if rising_edge(tb_clk_i) then
        if tb_rst_n_i = '0' then
          s_glitch_filt <= (others=>'0');
        else
          s_glitch_filt(0) <= tb_dat_i;
          s_glitch_filt(g_len downto 1) <= s_glitch_filt(g_len-1 downto 0);
        end if;
      end if;
    end process;
  end generate;
    
  -- Output data asserted when all FF's are '1' and de-asserted when all FF's
  -- are zero
  self_check : process(tb_clk_i)
  begin
    if (rising_edge(tb_clk_i) and tb_rst_n_i = '1') then
      if (unsigned(s_glitch_filt) = (s_glitch_filt'range => '1')) then
        assert (tb_dat_o = '1') 
          report "Output not HIGH when FF's are all HIGH" severity failure;
      elsif (unsigned(s_glitch_filt) = (s_glitch_filt'range => '0')) then
        assert (tb_dat_o = '0')
          report "Output not LOW when FF's are all LOW" severity failure;
      end if;
    end if;
  end process; 

  -- When output data is HIGH, we want the glitch filter to be anything but 0
  check_output : process(tb_clk_i)
  begin
    if (rising_edge(tb_clk_i) and tb_rst_n_i = '1') then
      if tb_dat_o = '1' then
        assert (unsigned(s_glitch_filt) /= (s_glitch_filt'range => '0'))
          report "FF's are all LOW when output is HIGH" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------
  
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset has asserted", ONE_BIN);
    cp_dat_o_high.AddBins("output pulse HIGH when FF's HIGH", ONE_BIN);
    wait;
  end process;

  sample_rst_cov : process
  begin
    loop
      wait on tb_rst_n_i;
      wait for C_CLK_PERIOD;
      --sample the coverpoints
      cp_rst_n_i.ICover(to_integer(tb_rst_n_i = '1'));
    end loop;
  end process;

  sample_dat_o_high : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_dat_o_high.ICover(to_integer((tb_dat_o = '1') 
                          and (unsigned(s_glitch_filt) = (s_glitch_filt'range => '1'))));
    end loop;
  end process;

  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_dat_o_high.Writebin;
  end process;

end tb;
    
