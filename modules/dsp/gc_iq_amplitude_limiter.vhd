

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;

entity ucc_rf_amplitude_limiter is
  port (
    clk_i  : in std_logic;
    rst_i  : in std_logic;

    i_i : in std_logic_vector(15 downto 0);
    q_i : in std_logic_vector(15 downto 0);

    i_o : out std_logic_vector(15 downto 0);
    q_o : out std_logic_vector(15 downto 0)

    limit_i : in std_logic_vector(31 downto 0);

    mag_o : out std_logic_vector(15 downto 0);
    phase_o : out std_logic_vector(15 downto 0);

    squelch_a_i : in std_logic
    );
end ucc_rf_amplitude_limiter;

architecture rtl of ucc_rf_amplitude_limiter is

  constant c_CORDIC_GAIN_SCALEFACTOR : signed(15 downto 0) := x"2f32";
  
  signal mag, phase, mag_limited : std_logic_vector(17 downto 0);
  signal is_mag_limited : std_logic;
  
begin


  
  
  U_Cart2Polar: entity work.gc_cordic
    generic map (
      g_N          => 18,
      g_M          => 18,
      g_ANGLE_MODE => FULL_SCALE_180)
    port map (
      clk_i         => clk_i,
      rst_i         => rst_i,
      cor_mode_i    => VECTOR,
      cor_submode_i => CIRCULAR,
      lim_x_i       => '0',
      lim_y_i       => '0',
      x0_i          => f_resize(i_i, 18),
      y0_i          => f_resize(q_i, 18),
      z0_i          => (others => '0'),
      xn_o          => mag,
      yn_o          => open,
      zn_o          => phase);

  p_limit : process(mag, limit_i)
  begin
    if unsigned(mag) > unsigned(limit_i) then
      is_mag_limited <= '1';
      mag_limited <= limit_i;
    else
      is_mag_limited <= '0';
      mag_limited <= mag;
      end if;
  end process;

  mag_o <= mag_limited(17 downto 2);
  phase_o <= phase(17 downto 2);

  U_Polar2Cart: entity work.gc_cordic
    generic map (
      g_N          => 16,
      g_M          => 18,
      g_ANGLE_MODE => FULL_SCALE_180)
    port map (
      clk_i         => clk_i,
      rst_i         => rst_i,
      cor_mode_i    => ROTATE,
      cor_submode_i => CIRCULAR,
      lim_x_i       => '0',
      lim_y_i       => '0',
      x0_i          => mag_limited,
      y0_i          => (others => '0'),
      z0_i          => phase,
      xn_o          => i_precomp,
      yn_o          => q_precomp);

end rtl;
