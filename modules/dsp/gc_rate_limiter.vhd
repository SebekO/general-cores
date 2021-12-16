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

entity gc_rate_limiter is
  generic (
    -- number of data bits
    g_DATA_BITS : positive := 16
    );
  port (
    clk_i : in std_logic;
    rst_i : in std_logic;

    rate_divider_i : in std_logic_vector(15 downto 0);
    rate_pos_i     : in std_logic_vector(g_DATA_BITS-1 downto 0);
    rate_neg_i     : in std_logic_vector(g_DATA_BITS-1 downto 0);

    bypass_i : in std_logic;

    limit_o     : out std_logic;
    limit_pos_o : out std_logic;
    limit_neg_o : out std_logic;

    valid_i : in std_logic;
    d_i     : in std_logic_vector(g_DATA_BITS-1 downto 0);

    valid_o : out std_logic;
    d_o     : out std_logic_vector(g_DATA_BITS-1 downto 0)
    );
end gc_rate_limiter;

architecture rtl of gc_rate_limiter is

  signal rate_cnt  : unsigned(15 downto 0);
  signal rate_tick : std_logic;

  signal dout_int, din_reg, delta : signed(g_DATA_BITS-1 downto 0);
  signal valid_d0, valid_d1       : std_logic;

  signal pos_over : std_logic;
  signal neg_over : std_logic;
  
begin

  p_gen_rate : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        rate_cnt  <= unsigned(rate_divider_i);
        rate_tick <= '0';
      elsif valid_d0 = '1' then
        if rate_cnt = 0 then
          rate_cnt  <= unsigned(rate_divider_i);
          rate_tick <= '1';
        else
          rate_cnt <= rate_cnt - 1;
        end if;
      else
        rate_tick <= '0';
      end if;
    end if;
  end process;

  delta    <= din_reg - dout_int;
  pos_over <= '1' when delta > signed(rate_pos_i) else '0';
  neg_over <= '1' when delta < signed(rate_neg_i) else '0';

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        dout_int <= (others => '0');
        valid_d0 <= '0';
        valid_d1 <= '0';
      else

        valid_d0 <= valid_i;
        valid_d1 <= valid_d0;
        
        din_reg <= signed(d_i);

        if bypass_i = '1' then
          dout_int    <= din_reg;
          limit_pos_o <= '0';
          limit_neg_o <= '0';
          limit_o     <= '0';
        elsif rate_tick = '1' then
          if pos_over = '1' and neg_over = '0' then
            limit_pos_o <= '1';
            limit_neg_o <= '0';
            limit_o     <= '1';
            dout_int    <= dout_int + signed(rate_pos_i);
          elsif pos_over = '0' and neg_over = '1' then
            limit_pos_o <= '1';
            limit_neg_o <= '0';
            limit_o     <= '1';
            dout_int    <= dout_int + signed(rate_neg_i);
          elsif pos_over = '1' and neg_over = '1' then
            limit_pos_o <= '1';
            limit_neg_o <= '1';
            limit_o     <= '1';
          else
            limit_pos_o <= '1';
            limit_neg_o <= '1';
            limit_o     <= '1';
            dout_int    <= din_reg;
          end if;
        end if;
      end if;
    end if;
  end process;

  valid_o <= valid_d1;
end rtl;
