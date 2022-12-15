-------------------------------------------------------------------------------
-- Title      : Testbench for a Dual channel PI controller for use in WR PLLs
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : tb_gc_dual_pi_controller.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN BE-CEM-EDL
-- Created    : 2021-12-21
-- Last update:
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for a Dual, programmable PI controller:
-- - first channel processes the frequency error (gain defined by P_KP/P_KI)
-- - second channel processes the phase error (gain defined by F_KP/F_KI)
-- Mode is selected by the mode_sel_i port and FORCE_F field in PCR register.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009 - 2010 CERN
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

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
--                   Entity declaration for tb_xwb_clock_bridge              --
--=============================================================================

entity tb_gc_dual_pi_controller is
  generic (
    g_seed                : natural;
    -- '1' for frequency mode, '0' for phase
    g_mode                : integer := 1;
    g_error_bits          : integer := 12;
    g_dacval_bits         : integer := 16;
    g_output_bias         : integer := 32767;
    g_integrator_fracbits : integer := 16;
    g_integrator_overbits : integer := 6;
    g_coef_bits           : integer := 16);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_gc_dual_pi_controller is
  -- constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;
  constant C_OUTPUT_BIAS : signed(g_dacval_bits + g_integrator_fracbits-1 downto 0) := to_signed(g_output_bias, g_dacval_bits) & to_signed(0, g_integrator_fracbits);

  constant C_INTEGRATOR_BITS : integer := g_error_bits + g_integrator_overbits + g_coef_bits;
  -- signals
  signal tb_clk_sys_i         : std_logic;
  signal tb_rst_n_sysclk_i    : std_logic;
  signal tb_phase_err_i       : std_logic_vector(g_error_bits-1 downto 0);
  signal tb_phase_err_stb_p_i : std_logic;
  signal tb_freq_err_i        : std_logic_vector(g_error_bits-1 downto 0);
  signal tb_freq_err_stb_p_i  : std_logic;
  signal tb_mode_sel_i        : std_logic;
  signal tb_dac_val_o         : std_logic_vector(g_dacval_bits-1 downto 0);
  signal tb_dac_val_stb_p_o   : std_logic;
  signal tb_pll_pcr_enable_i  : std_logic;
  signal tb_pll_pcr_force_f_i : std_logic;
  signal tb_pll_fbgr_f_kp_i   : std_logic_vector(g_coef_bits-1 downto 0);
  signal tb_pll_fbgr_f_ki_i   : std_logic_vector(g_coef_bits-1 downto 0);
  signal tb_pll_pbgr_p_kp_i   : std_logic_vector(g_coef_bits-1 downto 0);
  signal tb_pll_pbgr_p_ki_i   : std_logic_vector(g_coef_bits-1 downto 0);

  signal stop                 : boolean;
  signal s_freq_mode          : std_logic;
  signal s_dac_val_o          : unsigned(c_INTEGRATOR_BITS-1 downto 0) := (others=>'0');
  signal s_rounded_val_o      : unsigned(g_dacval_bits-1 downto 0);
  signal s_reg_i              : signed(c_INTEGRATOR_BITS-1 downto 0);
  signal s_sat_hi             : std_logic;
  signal s_sat_lo             : std_logic;
  signal s_data_o             : std_logic_vector(g_dacval_bits-1 downto 0);
  signal s_round_up           : std_logic := '0';
  -- needed to describe the saturation
  signal s_ones               : std_logic_vector(g_dacval_bits-1 downto 0) := (others=>'1');
  signal s_zeros              : std_logic_vector(g_dacval_bits-1 downto 0) := (others=>'0');
  signal mula                 : signed(g_error_bits-1 downto 0);
  signal mulb                 : signed(g_coef_bits-1 downto 0);
  signal mulo                 : signed(g_error_bits+g_coef_bits-1 downto 0);
  signal s_mulo_reg           : signed(g_error_bits+g_coef_bits-1 downto 0);

  type t_dmpll_state is
    ( PI_CHECK_MODE,
      PI_WAIT_SAMPLE,
      PI_MUL_KI,
      PI_INTEGRATE,
      PI_MUL_KP,
      PI_CALC_SUM,
      PI_SATURATE,
      PI_ROUND_SUM,
      PI_DISABLED);

  signal pi_state : t_dmpll_state;

  shared variable sv_cover : covPType;

  --------------------------------------------------------------------------------
  --                        Procedures used for fsm coverage                    --
  --------------------------------------------------------------------------------

  -- states
  procedure fsm_covadd_states (
    name  : in string;
    prev  : in t_dmpll_state;
    curr  : in t_dmpll_state;
    covdb : inout covPType) is
  begin
    covdb.AddCross ( name,
                     GenBin(t_dmpll_state'pos(prev)),
                     GenBin(t_dmpll_state'pos(curr)));
    wait;
  end procedure;

  -- illegal
  procedure fsm_covadd_illegal (
    name  : in string;
    covdb : inout covPType ) is
  begin
    covdb.AddCross(ALL_ILLEGAL,ALL_ILLEGAL);
    wait;
  end procedure;

  -- collection
  procedure fsm_covcollect (
    signal reset : in std_logic;
    signal clk   : in std_logic;
    signal state : in t_dmpll_state;
           covdb : inout covPType) is
    variable v_state : t_dmpll_state := t_dmpll_state'left;
  begin
    wait until reset='1';
    loop
      v_state := state;
      wait until rising_edge(clk);
      covdb.ICover((t_dmpll_state'pos(v_state), t_dmpll_state'pos(state)));
    end loop;
  end procedure;

begin

  -- Unit Under Test
  UUT : entity work.gc_dual_pi_controller
  generic map (
    g_error_bits          => g_error_bits,
    g_dacval_bits         => g_dacval_bits,
    g_output_bias         => g_output_bias,
    g_integrator_fracbits => g_integrator_fracbits,
    g_integrator_overbits => g_integrator_overbits,
    g_coef_bits           => g_coef_bits)
  port map (
    clk_sys_i         => tb_clk_sys_i,
    rst_n_sysclk_i    => tb_rst_n_sysclk_i,
    phase_err_i       => tb_phase_err_i,
    phase_err_stb_p_i => tb_phase_err_stb_p_i,
    freq_err_i        => tb_freq_err_i,
    freq_err_stb_p_i  => tb_freq_err_stb_p_i,
    mode_sel_i        => tb_mode_sel_i,
    dac_val_o         => tb_dac_val_o,
    dac_val_stb_p_o   => tb_dac_val_stb_p_o,
    pll_pcr_enable_i  => tb_pll_pcr_enable_i,
    pll_pcr_force_f_i => tb_pll_pcr_force_f_i,
    pll_fbgr_f_kp_i   => tb_pll_fbgr_f_kp_i,
    pll_fbgr_f_ki_i   => tb_pll_fbgr_f_ki_i,
    pll_pbgr_p_kp_i   => tb_pll_pbgr_p_kp_i,
    pll_pbgr_p_ki_i   => tb_pll_pbgr_p_ki_i);

  -- Clock generation
  clk_sys_proc : process
  begin
    while STOP = FALSE loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process clk_sys_proc;

  -- reset generation
  tb_rst_n_sysclk_i <= '0', '1' after 4*C_CLK_SYS_PERIOD;

  -- Stimulus
  stim : process
      variable ncycles : natural;
      variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until (rising_edge(tb_clk_sys_i) and tb_rst_n_sysclk_i = '1');
      -- general I/O
      tb_pll_pcr_enable_i  <= data.randSlv(1)(1);
      -- frequency mode
      tb_freq_err_i        <= data.randSlv(g_error_bits);
      tb_freq_err_stb_p_i  <= data.randSlv(1)(1);
      tb_pll_fbgr_f_kp_i   <= data.randSlv(g_coef_bits);
      tb_pll_fbgr_f_ki_i   <= data.randSlv(g_coef_bits);
      -- phase mode
      tb_phase_err_i       <= data.randSlv(g_error_bits);
      tb_phase_err_stb_p_i <= data.randSlv(1)(1);
      tb_pll_pbgr_p_kp_i   <= data.randSlv(g_coef_bits);
      tb_pll_pbgr_p_ki_i   <= data.randSlv(g_coef_bits);
      wait for 100 ns;
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    report "Test PASS!";
    wait;
  end process stim;

  -- Frequency mode when '1'
  -- Phase mode when '0'
  tb_mode_sel_i <= '1' when g_mode = 1 else '0';
  tb_pll_pcr_force_f_i <= '1' when g_mode = 1 else '0';

  --------------------------------------------------------------------------------
  --                                  Coverage                                  --
  --------------------------------------------------------------------------------

  -- FSM
  p_fsm : process(tb_clk_sys_i,tb_rst_n_sysclk_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_sysclk_i = '0' then
        pi_state <= PI_CHECK_MODE;
        s_freq_mode <= '1';
        s_reg_i <= (others=>'0');
        s_data_o <= std_logic_vector(to_unsigned(g_output_bias,s_data_o'length));
      else
        case pi_state is
          when PI_DISABLED =>

            if (tb_pll_pcr_enable_i = '1') then
              pi_state <= PI_CHECK_MODE;
            end if;

          when PI_CHECK_MODE =>

            if (tb_pll_pcr_force_f_i = '0') then
              s_freq_mode <= tb_mode_sel_i;
            else
              s_freq_mode <= '1';
            end if;

            if (tb_pll_pcr_enable_i = '1') then
              pi_state <= PI_WAIT_SAMPLE;
            else
              pi_state <= PI_DISABLED;
              s_freq_mode <= '1';
            end if;

            when PI_WAIT_SAMPLE =>

              if (s_freq_mode = '1' and tb_freq_err_stb_p_i = '1') then
                pi_state <= PI_MUL_KI;
                mula <= signed(tb_freq_err_i);
                mulb <= signed(tb_pll_fbgr_f_ki_i);
              elsif (s_freq_mode = '0' and tb_phase_err_stb_p_i = '1') then
                pi_state <= PI_MUL_KI;
                mula <= signed(tb_phase_err_i);
                mulb <= signed(tb_pll_pbgr_p_ki_i);
              end if;

            when PI_MUL_KI =>

              if (s_freq_mode = '1') then
                mulb <= signed(tb_pll_fbgr_f_kp_i);
              else
                mulb <= signed(tb_pll_pbgr_p_kp_i);
              end if;
                s_mulo_reg <= mulo;
                pi_state <= PI_INTEGRATE;

             when PI_INTEGRATE =>

              if (s_sat_lo = '0' and s_sat_hi = '0') then
                s_reg_i <= s_reg_i + s_mulo_reg;
              end if;

              if (s_sat_hi = '1' and s_mulo_reg(s_mulo_reg'high) = '1') or (s_sat_lo = '1' and s_mulo_reg(s_mulo_reg'high) = '0') then
                s_reg_i <= s_reg_i + s_mulo_reg;
              end if;

              pi_state <= PI_MUL_KP;

            when PI_MUL_KP =>

              s_mulo_reg <= mulo;
              pi_state <= PI_CALC_SUM;

            when PI_CALC_SUM =>
              --output_val calculation
              s_dac_val_o <= unsigned(C_OUTPUT_BIAS + resize(s_mulo_reg, s_dac_val_o'length) + resize(s_reg_i, s_dac_val_o'length));

              pi_state <= PI_SATURATE;

            when PI_SATURATE =>

              -- if sat_hi = '1'
              if (tb_dac_val_o = s_ones) then
                pi_state <= PI_CHECK_MODE;
                s_sat_hi <= '1';
                s_sat_lo <= '0';
              -- if sat_lo = '1'
              elsif (tb_dac_val_o = s_zeros) then
                pi_state <= PI_CHECK_MODE;
                s_sat_hi <= '0';
                s_sat_lo <= '1';
              -- if no saturation
              else
                s_sat_hi <= '0';
                s_sat_lo <= '0';
                pi_state <= PI_ROUND_SUM;
              end if;


            when PI_ROUND_SUM =>

              if (s_round_up = '1') then
                s_data_o <= std_logic_vector(s_rounded_val_o+1);
              else
                s_data_o <= std_logic_vector(s_rounded_val_o);
              end if;
                pi_state <= PI_CHECK_MODE;

            when others => null;

        end case;
      end if;
    end if;
  end process;

  -- all possible legal changes
  fsm_covadd_states("PI_DISABLED    ->PI_CHECK_MODE ",PI_DISABLED,   PI_CHECK_MODE ,sv_cover);
  fsm_covadd_states("PI_CHECK_MODE  ->PI_DISABLED   ",PI_CHECK_MODE, PI_DISABLED   ,sv_cover);
  fsm_covadd_states("PI_CHECK_MODE  ->PI_WAIT_SAMPLE",PI_CHECK_MODE, PI_WAIT_SAMPLE,sv_cover);
  fsm_covadd_states("PI_WAIT_SAMPLE ->PI_MUL_KI     ",PI_WAIT_SAMPLE,PI_MUL_KI     ,sv_cover);
  fsm_covadd_states("PI_MUL_KI      ->PI_INTEGRATE  ",PI_MUL_KI,     PI_INTEGRATE  ,sv_cover);
  fsm_covadd_states("PI_INTEGRATE   ->PI_MUL_KP     ",PI_INTEGRATE,  PI_MUL_KP     ,sv_cover);
  fsm_covadd_states("PI_MUL_KP      ->PI_CALC_SUM   ",PI_MUL_KP,     PI_CALC_SUM   ,sv_cover);
  fsm_covadd_states("PI_CALC_SUM    ->PI_SATURATE   ",PI_CALC_SUM,   PI_SATURATE   ,sv_cover);
  fsm_covadd_states("PI_SATURATE    ->PI_ROUND_SUM  ",PI_SATURATE,   PI_ROUND_SUM  ,sv_cover);
  fsm_covadd_states("PI_SATURATE    ->PI_CHECK_MODE ",PI_SATURATE,   PI_CHECK_MODE ,sv_cover);
  fsm_covadd_states("PI_ROUND_SUM   ->PI_CHECK_MODE ",PI_ROUND_SUM,  PI_CHECK_MODE ,sv_cover);
  -- when current and next state is the same
  fsm_covadd_states("PI_DISABLED    ->PI_DISABLED   ",PI_DISABLED,   PI_DISABLED   ,sv_cover);
  fsm_covadd_states("PI_CHECK_MODE  ->PI_CHECK_MODE ",PI_CHECK_MODE, PI_CHECK_MODE ,sv_cover);
  fsm_covadd_states("PI_WAIT_SAMPLE ->PI_WAIT_SAMPLE",PI_WAIT_SAMPLE,PI_WAIT_SAMPLE,sv_cover);
  -- illegal states
  fsm_covadd_illegal("ILLEGAL",sv_cover);

  -- collect the cov bins
  fsm_covcollect(tb_rst_n_sysclk_i, tb_clk_sys_i, pi_state, sv_cover);

  -- coverage report
  cov_report : process
  begin
    wait until stop;
    sv_cover.writebin;
    report "Test PASS!";
  end process;

  --------------------------------------------------------------------------------
  --                              Self - Checking                               --
  --------------------------------------------------------------------------------

  -- Mode selection
  assert (g_mode = 1 or g_mode = 0)
    report "wrong mode selected" severity failure;

  -- Used to multiply two values
  multiply : process(mula,mulb)
  begin
    mulo <= mula * mulb;
  end process;

  s_round_up      <= std_logic(s_dac_val_o(g_integrator_fracbits - 1));
  s_rounded_val_o <= s_dac_val_o(g_integrator_fracbits + g_dacval_bits - 1 downto g_integrator_fracbits);

  out_check : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_sysclk_i = '1' then
        if rising_edge(tb_dac_val_stb_p_o) then
          assert (s_data_o = tb_dac_val_o)
            report "Output data mismatch" severity failure;
        end if;
      end if;
    end if;
  end process;

end tb;
