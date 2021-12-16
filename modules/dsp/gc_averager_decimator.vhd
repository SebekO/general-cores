------------------------------------------
------------------------------------------
-- Date        : Fri Aug 21 14:48:22 2015
--
-- Author      : Daniel Valuch
--
-- Company     : CERN BE/RF/FB
--
-- Description : Moving average filter/decimator. Two channels.
--
------------------------------------------
------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity gc_averager_decimator is
  generic (
    -- number of data bits
    g_INPUT_BITS : positive := 24;
    g_OUTPUT_BITS : positive := 16
    );
  port (
    clk_i  : in std_logic;
    rst_i  : in std_logic;
    sync_i : in std_logic;

    dec_factor_i : in std_logic_vector(3 downto 0);

    valid_i : in std_logic;
    ch1_d_i : in std_logic_vector(g_INPUT_BITS-1 downto 0);
    ch2_d_i : in std_logic_vector(g_INPUT_BITS-1 downto 0);

    valid_o : out std_logic;
    ch1_d_o : out std_logic_vector(g_OUTPUT_BITS-1 downto 0);
    ch2_d_o : out std_logic_vector(g_OUTPUT_BITS-1 downto 0)

    );
end gc_averager_decimator;

architecture rtl of gc_averager_decimator is

  signal decim_cnt      : unsigned(15 downto 0);
  signal decim_cnt_init : unsigned(15 downto 0);

  signal ch1_acc, ch2_acc : signed(31 downto 0);

  function f_sar(x : signed; shift : std_logic_vector; out_size : positive) return std_logic_vector is
  begin
    return std_logic_vector(Resize (shift_right(x, to_integer(unsigned(shift))), out_size));
  end f_sar;

begin


  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' or sync_i = '1' then
        ch1_acc   <= signed(ch1_d_i);
        ch2_acc   <= signed(ch2_d_i);
        ch1_d_o   <= (others => '0');
        ch2_d_o   <= (others => '0');
        valid_o   <= '0';
        decim_cnt <= decim_cnt_init;
      elsif valid_i = '1' then
        if decim_cnt = 0 then
          valid_o   <= '1';
          ch1_acc   <= signed(ch1_d_i);
          ch2_acc   <= signed(ch2_d_i);
          ch1_d_o     <= f_sar(ch1_acc, dec_factor_i, g_OUTPUT_BITS);
          ch2_d_o     <= f_sar(ch2_acc, dec_factor_i, g_OUTPUT_BITS);
          decim_cnt <= decim_cnt_init;
        else
          ch1_acc <= ch1_acc + signed(ch1_d_i);
          ch2_acc <= ch2_acc + signed(ch2_d_i);
        end if;

      else
        valid_o <= '0';
      end if;
    end if;
  end process;
end rtl;
