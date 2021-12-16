------------------------------------------
------------------------------------------
-- Date        : Sat Jul 11 15:15:22 2015
--
-- Author      : Daniel Valuch
--
-- Company     : CERN BE/RF/FB
--
-- Description : 
--
------------------------------------------
------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- phase rotation in vector domain
-- I' = A * ( I*cos theta + Q*sin theta)
-- Q' = A * (-I*sin theta + Q*sin theta)
-- scaling: 0 < A < 32767

entity gc_iq_rotate is
  generic (
    -- number of data bits
    g_SAMPLE_BITS : positive := 24;
    g_SINCOS_BITS : positive := 16
    );
  port (
    clk_i : in std_logic;
    rst_i : in std_logic;

    i_i     : in std_logic_vector(g_SAMPLE_BITS-1 downto 0);
    q_i     : in std_logic_vector(g_SAMPLE_BITS-1 downto 0);
    sin_i   : in std_logic_vector(g_SINCOS_BITS-1 downto 0);
    cos_i   : in std_logic_vector(g_SINCOS_BITS-1 downto 0);
    valid_i : in std_logic;

    i_o     : out std_logic_vector(g_SAMPLE_BITS-1 downto 0);
    q_o     : out std_logic_vector(g_SAMPLE_BITS-1 downto 0);
    valid_o : out std_logic
    );
end gc_iq_rotate;

architecture rtl of gc_iq_rotate is

  constant c_MUL_BITS : integer := g_SAMPLE_BITS + g_SINCOS_BITS;

  signal isum, qsum, icos, isin, qcos, qsin : signed(c_MUL_BITS-1 downto 0);
begin

  isin <= signed(i_i) * signed(sin_i);
  icos <= signed(i_i) * signed(cos_i);
  qsin <= signed(q_i) * signed(sin_i);
  qcos <= signed(q_i) * signed(cos_i);

  isum <= icos - qsin;
  qsum <= qcos + isin;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        i_o     <= (others => '0');
        q_o     <= (others => '0');
        valid_o <= '0';
      else
        i_o     <= std_logic_vector(isum(c_MUL_BITS-2 downto c_MUL_BITS-2-g_SAMPLE_BITS+1));
        q_o     <= std_logic_vector(qsum(c_MUL_BITS-2 downto c_MUL_BITS-2-g_SAMPLE_BITS+1));
        valid_o <= valid_i;
      end if;
    end if;
  end process;

end rtl;
