library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

entity tb_gc_big_adder is
	generic (
		g_data_bits : natural := 64;
		g_parts     : natural := 4);
end entity tb_gc_big_adder;

architecture tb of tb_gc_big_adder is

	-- Signal declarations
	signal tb_clk_i   : std_logic;
	signal tb_stall_i : std_logic;
	signal tb_a_i	  : std_logic_vector(g_data_bits-1 downto 0);
	signal tb_b_i     : std_logic_vector(g_data_bits-1 downto 0);
	signal tb_c_i     : std_logic;
	signal tb_c1_o	  : std_logic;
	signal tb_x2_o    : std_logic_vector(g_data_bits-1 downto 0);
	signal tb_c2_o    : std_logic;
	signal tb_sim_end : std_logic;

begin
	
	-- Unit Under Test instantiation
	UUT : entity work.gc_big_adder
	generic map (
		g_data_bits => g_data_bits,
		g_parts     => g_parts)
	port map (
    		clk_i   => tb_clk_i,
    		stall_i => tb_stall_i,
    		a_i     => tb_a_i,
    		b_i     => tb_b_i,
    		c_i 	=> tb_c_i,
    		c1_o    => tb_c1_o,
    		x2_o    => tb_x2_o,
    		c2_o    => tb_c2_o);

	  -- Clock process definitions
  	clk_i_process : process
  	begin
    		while tb_sim_end /= '1' loop
      	  		tb_clk_i <= '0';
      	  		wait for 5 NS;
      	  		tb_clk_i <= '1';
      	  		wait for 5 NS;
    	  	end loop;
    		wait;
  	end process;

	-- Stimulus process
	stim_proc : process
		procedure wait_clock_rising(
			constant cycles : in integer) is
		begin
			for i in 1 to cycles loop
				wait until rising_edge(tb_clk_i);
			end loop;
		end procedure wait_clock_rising;

		procedure assign_input (
			constant value_a     : in integer;
			constant value_b     : in integer;
			constant value_c     : in std_logic;
			constant wait_cycles : in integer) is
		begin
			wait_clock_rising(wait_cycles);
			wait until falling_edge(tb_clk_i);
			tb_a_i <= std_logic_vector(to_signed(value_a,g_data_bits));
			tb_b_i <= std_logic_vector(to_signed(value_b,g_data_bits));
			tb_c_i <= value_c;
		end procedure assign_input;

	begin
		-- initial values
		tb_sim_end <= '0';
		tb_a_i     <= (others=>'0');
		tb_b_i     <= (others=>'0');
		tb_stall_i <= '1';
		tb_c_i     <= '0';

		-- hold stall for 100ns
		wait_clock_rising(5);
		tb_stall_i <= '0';
		
		assign_input(4,4,'0',2);
		wait_clock_rising(20);

		assign_input(4,4,'1',2); 
		wait_clock_rising(20);

		assign_input(10,10,'1',2); 
		wait_clock_rising(20);
		
		assign_input(12,12,'0',2); 
		wait_clock_rising(20);
		tb_sim_end <= '1';

		wait;
	end process;
end tb;
