-- SPDX-FileCopyrightText: 2023 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

--  Simple testbench for generic_async_fifo_mixedw
library ieee;
use ieee.std_logic_1164.all;

entity tb_fifo is
end;

architecture arch of tb_fifo is
  signal start_32_64 : std_logic := '0';
  signal done_32_64 : std_logic;

  signal start_8_32 : std_logic := '0';
  signal done_8_32 : std_logic;

  signal start_32_8_a : std_logic := '0';
  signal done_32_8_a : std_logic;

  signal start_32_64_a : std_logic := '0';
  signal done_32_64_a : std_logic;

  signal start_64_32 : std_logic := '0';
  signal done_64_32 : std_logic;

  signal start_64_32_a : std_logic := '0';
  signal done_64_32_a : std_logic;
begin
  dut_8_32: entity work.tb_8_32
    port map (start_8_32, done_8_32);

  dut_32_8_a: entity work.tb_32_8_ahead
    port map (start_32_8_a, done_32_8_a);

  dut_32_64: entity work.tb_32_64
    generic map (g_show_ahead => False)
    port map (start_32_64, done_32_64);

  dut_32_64_a: entity work.tb_32_64
    generic map (g_show_ahead => False)
    port map (start_32_64_a, done_32_64_a);

  dut_64_32: entity work.tb_64_32
    generic map (g_show_ahead => false)
    port map (start_64_32, done_64_32);

  dut_64_32_a: entity work.tb_64_32
    generic map (g_show_ahead => True)
    port map (start_64_32_a, done_64_32_a);

  process
  begin
    wait for 1 ns;
    start_8_32 <= '1';
    wait until done_8_32 = '1';

    wait for 10 ns;
    start_32_8_a <= '1';
    wait until done_32_8_a = '1';

    wait for 10 ns;
    start_32_64 <= '1';
    wait until done_32_64 = '1';

    wait for 10 ns;
    start_32_64_a <= '1';
    wait until done_32_64_a = '1';

    wait for 10 ns;
    start_64_32 <= '1';
    wait until done_64_32 = '1';

    wait for 10 ns;
    start_64_32_a <= '1';
    wait until done_64_32_a = '1';

    wait for 8 ns;
    wait;
  end process;
end arch;
