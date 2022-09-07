--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_gc_dyn_extend_pulse
--
-- author : Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- description: Synchronous pulse extender. Generates a pulse of programmable
-- width upon detection of a rising edge in the input.
--
--------------------------------------------------------------------------------
-- Copyright CERN 209-2018
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
--                   Entity declaration for tb_gc_dyn_extend_pulse           --
--=============================================================================

entity tb_gc_dyn_extend_pulse is
  generic (
    g_seed      : natural;
    g_len_width : natural := 1);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_dyn_extend_pulse is
    
  --Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i      : std_logic;
  signal tb_rst_n_i    : std_logic;
  signal tb_pulse_i    : std_logic;
  signal tb_len_i      : std_logic_vector(g_len_width-1 downto 0) := (others=>'0');
  signal tb_extended_o : std_logic := '0';
  signal stop  : boolean;
  signal s_cnt : unsigned(g_len_width-1 downto 0) := (others=>'0');

  -- Shared variables, used for coverage
  shared variable cp_rst_n_i      : covPType;
  shared variable cp_pulse_detect : covPType;
  shared variable cp_ext_pulse_o  : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_dyn_extend_pulse
  generic map (
    g_len_width => g_len_width)
  port map (
    clk_i      => tb_clk_i,
    rst_n_i    => tb_rst_n_i,
    pulse_i    => tb_pulse_i,
    len_i      => tb_len_i,
    extended_o => tb_extended_o);

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
    variable ncycles 	: natural;
    variable data     : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while (NOW < 2 ms) loop
      wait until (rising_edge(tb_clk_i) and tb_rst_n_i = '1');
      tb_pulse_i <= data.randSlv(1)(1);
      tb_len_i   <= data.randSlv(g_len_width) when tb_pulse_i = '1' else (others=>'0');
      ncycles    := ncycles + 1;
    end loop;
    report "Number of Simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                            Assertions                                      --
  --------------------------------------------------------------------------------

  -- The extended output pulse should not be asserted for a period more than
  -- len_i between two rising edges of input pulse
  -- So, extended_o shouldn't be high for a period longer than
  -- this when pulse_i is falling_edge
  
  p_cnt : process(tb_clk_i)
  begin
    if tb_rst_n_i = '0' then
      s_cnt <= (others=>'0');
    elsif rising_edge(tb_clk_i) then
      if (tb_pulse_i = '0' and tb_extended_o = '1') then
        s_cnt <= s_cnt + 1;
      else
        s_cnt <= (others=>'0');
      end if;
    end if;
  end process;

  -- Check the width of the output pulse
  -- not to be higher then len_i
  check_extended_o : process(tb_clk_i)
  begin
    if (tb_rst_n_i = '1') then
    elsif rising_edge(tb_clk_i) then
        assert (s_cnt <= unsigned(tb_len_i))
          report "Output pulse high for longer period" severity failure;
    end if;
  end process;


  -- Output extended pulse is rising when input pulse is asserted
  both_high : process(tb_clk_i)
  begin
    if (rising_edge(tb_clk_i) and tb_rst_n_i = '1') then
      if (tb_pulse_i = '1') then
        assert (tb_extended_o = '1')
          report "Output pulse not high when input pulse is high" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                              Coverage                                      --
  --------------------------------------------------------------------------------
    
  -- Set up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset has asserted", ONE_BIN);
    cp_pulse_detect.AddBins("output pulse high when input high", ONE_BIN);
    cp_ext_pulse_o.AddBins("output pulse high when input is low", ONE_BIN);
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

  sample_pulse_detect : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_pulse_detect.ICover(to_integer((tb_pulse_i = '1') 
                                        and tb_extended_o = '1'));
    end loop;
  end process;

  sample_out_pulse : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      if (s_cnt = g_len_width-1) then
        cp_ext_pulse_o.ICover(to_integer(tb_extended_o = '1' and tb_pulse_i = '0'));
      end if;
    end loop;
  end process;

  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.Writebin;
    cp_pulse_detect.Writebin;
    cp_ext_pulse_o.Writebin;
  end process;

end tb;
