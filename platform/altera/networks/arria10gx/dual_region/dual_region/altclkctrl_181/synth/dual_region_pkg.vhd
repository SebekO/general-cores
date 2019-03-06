library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package dual_region_pkg is
	component dual_region_altclkctrl_181_cf6o3fq is
		port (
			inclk  : in  std_logic := 'X'; -- inclk
			outclk : out std_logic         -- outclk
		);
	end component dual_region_altclkctrl_181_cf6o3fq;

end dual_region_pkg;
