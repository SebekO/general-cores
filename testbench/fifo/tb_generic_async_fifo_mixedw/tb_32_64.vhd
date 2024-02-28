-- SPDX-FileCopyrightText: 2023 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

--  Simple testbench for generic_async_fifo_mixedw
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_32_64 is
  generic (g_show_ahead : boolean);
  port (start : std_logic := '1';
        done : out std_logic);
end;

architecture arch of tb_32_64 is
  constant g_wr_width : natural := 32;
  constant g_rd_width : natural := 64;
  constant g_size : natural := 4;

  signal rst_n, clk_wr, clk_rd, we, rd, full, empty : std_logic;
  signal d : std_logic_vector(g_wr_width -1 downto 0);
  signal q : std_logic_vector(g_rd_width-1 downto 0);
  signal wr_count : std_logic_vector(3 downto 0);
  signal rd_count : std_logic_vector(2 downto 0);
begin
  dut: entity work.generic_async_fifo_mixedw
    generic map (
      g_wr_width => g_wr_width,
      g_rd_width => g_rd_width,
      g_size => g_size,
      g_show_ahead => g_show_ahead,
      g_memory_implementation_hint => open
    )
    port map (
      rst_n_a_i => rst_n,
      clk_wr_i => clk_wr,
      d_i => d,
      we_i => we,
      wr_full_o => full,
      wr_count_o => wr_count,
      clk_rd_i => clk_rd,
      q_o => q,
      rd_i => rd,
      rd_empty_o => empty,
      rd_count_o => rd_count
    );

  process
    procedure pulse_w is
    begin
      clk_wr <= '0';
      wait for 5 ns;
      clk_wr <= '1';
      wait for 5 ns;
    end pulse_w;

    procedure pulse_r is
    begin
      clk_rd <= '0';
      wait for 1 ns;
      clk_rd <= '1';
      wait for 1 ns;
    end pulse_r;
  begin
    done <= '0';
    if start /= '1' then
      wait until start = '1';
    end if;

    rst_n <= '0';
    we <= '0';
    rd <= '0';
    pulse_w;
    pulse_r;

    rst_n <= '1';
    for i in 1 to 2 loop
      pulse_w;
      pulse_r;
    end loop;

    assert empty = '1' report "fifo must be empty after reset";
    assert full = '0' report "fifo must not be full after reset";
    assert unsigned(rd_count) = 0 report "rd_count must be 0 after reset";
    assert unsigned(wr_count) = 0 report "wr_count must be 0 after reset";

    d <= x"01_02_03_04";
    we <= '1';
    pulse_w;
    d <= x"05_06_07_08";
    pulse_w;
    assert full = '0';
    we <= '0';

    while empty = '1' loop
      pulse_w;
      pulse_r;
    end loop;

    rd <= '1';
    if not g_show_ahead then
      pulse_r;
    end if;

    assert q = x"05_06_07_08_01_02_03_04";

    if g_show_ahead then
      pulse_r;
    end if;
    rd <= '0';
    assert empty = '1';

    report "End of 32_64 testbench";
    done <= '1';
    wait;
  end process;
end arch;
