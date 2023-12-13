--------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- author : Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- unit name:   tb_gc_edge_detect
--
-- description: testbench for simple edge detector
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

library common_lib;

entity tb_gc_edge_detect is
  generic (
    runner_cfg   : string;
    g_seed       : natural;
    g_clk_cycles : natural;
    g_ASYNC_RST  : boolean := FALSE;
    g_PULSE_EDGE : string  := "positive";
    g_CLOCK_EDGE : string  := "positive");
end entity;

architecture tb of tb_gc_edge_detect is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal tb_clk_i   : std_logic;
  signal tb_rst_i   : std_logic;
  signal tb_d_i     : std_logic;
  signal tb_pulse_o : std_logic;
  signal stop       : boolean := false;

  -- Shared variables, used for coverage
  shared variable cp_rst_i : covPType;
  shared variable rnd      : RandomPType;

begin

  -- Clock generation
  p_clk_proc : process
  begin
    while true loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
  end process p_clk_proc;

  -- Reset generation
  tb_rst_i <= '0', '1' after 10*C_CLK_PERIOD;

  --------------------------------------------------------------------------
  --! Main Test Process required by VUnit
  p_main_test : process
  begin
    test_runner_setup(runner, runner_cfg);
	rnd.InitSeed(g_seed);
	info("[STARTING] Seed = " & integer'image(g_seed));
	while test_suite loop
      reset_checker_stat;

      if run("test_edge_detect") then
        tb_d_i <= '0';
        wait until rising_edge(tb_rst_i);
        for i in 0 to g_clk_cycles-1 loop
          wait until rising_edge(tb_clk_i);
          tb_d_i <= rnd.randSlv(1)(1);
        end loop;
      end if;

    end loop;
    stop <= true;
	test_runner_cleanup(runner);
  end process p_main_test;

  -- Timeout watchdog (optional)
  test_runner_watchdog(runner, 2 ms);

  --sets up coverpoint bins
  p_init_coverage : process
  begin
    cp_rst_i.AddBins("reset has asserted", ONE_BIN);
    wait;
  end process p_init_coverage;

  --Assertion to check that the width of the output
  --pulse is asserted for only one clock cycle
  p_one_clk_width : process
  begin
    while true loop
      wait until rising_edge(tb_pulse_o);
      wait until rising_edge(tb_clk_i);
      wait for 1 ps; --minor time delay just for the simulator to detect the change
      check_equal(tb_pulse_o,'0',"Wrond duration of the output pulse");
    end loop;
  end process p_one_clk_width;

  --Assertion to verify the output based on the clock edge
  gen_pos_edge : if g_CLOCK_EDGE = "positive" generate

    p_pos_check_output : process
    begin
      wait until rising_edge(tb_clk_i);
      if rising_edge(tb_d_i) then
        check_equal(tb_pulse_o,'1',"Pulse not detected in positive clk edge");
      end if;
    end process p_pos_check_output;

  end generate gen_pos_edge;

  gen_neg_edge : if g_CLOCK_EDGE = "negative" generate

    p_neg_check_output : process
    begin
      wait until rising_edge(tb_clk_i);
      if falling_edge(tb_d_i) then
        check_equal(tb_pulse_o,'1',"Pulse not detected when negative clk edge");
      end if;
    end process p_neg_check_output;

  end generate gen_neg_edge;

  p_sample_cov : process
  begin
    loop
      wait on tb_rst_i;
      wait for C_CLK_PERIOD;
      --sample the coverpoints
      cp_rst_i.ICover(to_integer(tb_rst_i = '1'));
    end loop;
  end process p_sample_cov;

  p_cover_report: process
  begin
    wait until stop;
    report"**** Coverage Report ****";
    cp_rst_i.writebin;
    report "";
  end process p_cover_report;

  -- Unit Under Test
  UUT : entity common_lib.gc_edge_detect
  generic map (
    g_ASYNC_RST  => g_ASYNC_RST,
    g_PULSE_EDGE => g_PULSE_EDGE,
    g_CLOCK_EDGE => g_CLOCK_EDGE)
  port map (
    clk_i   => tb_clk_i,
    rst_n_i => tb_rst_i,
    data_i  => tb_d_i,
    pulse_o => tb_pulse_o);

end architecture tb;
