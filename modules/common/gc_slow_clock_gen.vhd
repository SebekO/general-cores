------------------------------------------
------------------------------------------
-- Date        : Fri Aug 21 14:48:22 2015
--
-- Author      : Daniel Valuch
--
-- Company     : CERN BE/RF/FB
--
-- Description : Function rise/fall speed limiter
--
------------------------------------------
------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity gc_slow_clock_gen is
  generic (
    -- number of data bits
    g_DATA_BITS : positive := 16
    );
  port (
    clk_i : in std_logic;
    rst_i : in std_logic;

    enable_i       : in  std_logic;
    rate_divider_i : in  std_logic_vector(15 downto 0);
    tick_o         : out std_logic
    );
end gc_slow_clock_gen;

architecture rtl of gc_slow_clock_gen is

  signal rate_cnt  : unsigned(15 downto 0);
  signal rate_tick : std_logic;

begin

  p_gen_rate : process(clk_i, rst_i)
  begin
    if rst_i = '1' then
      rate_cnt  <= unsigned(rate_divider_i);
      rate_tick <= '0';
    elsif enable_i = '1' then
      if rate_cnt = 0 then
        rate_cnt  <= unsigned(rate_divider_i);
        rate_tick <= '1';
      else
        rate_cnt <= rate_cnt - 1;
      end if;
    else
      rate_tick <= '0';
    end if;
  end process;

  tick_o <= rate_tick;
end rtl;
