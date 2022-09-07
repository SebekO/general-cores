-------------------------------------------------------------------------------
-- Title      : Testbench for serial DAC interface
-- Project    : White Rabbit - General Cores
-------------------------------------------------------------------------------
-- File       : tb_gc_serial_dac.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN BE-CEM-EDL
-- Created    : 2021-12-17
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for the DAC unit provides an interface to a 16 bit 
-- serial Digital to Analogue converter (MAX5441, AD5662, SPI/QSPI/MICROWIRE 
-- compatible) 
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009 - 2010 CERN
--
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the "License") (which enables you, at your option,
-- to treat this file as licensed under the Apache License 2.0); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://solderpad.org/licenses/SHL-0.51.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_serial_dac is
  generic (
    g_seed : natural;
    g_num_data_bits  : integer := 2; 
    g_num_extra_bits : integer := 0;
    g_num_cs_select  : integer := 1;
    g_sclk_polarity  : integer := 0);
end entity;

architecture tb of tb_gc_serial_dac is

  -- constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- signals
  signal tb_clk_i         : std_logic;
  signal tb_rst_n_i       : std_logic;
  signal tb_value_i       : std_logic_vector(g_num_data_bits-1 downto 0) := (others=>'0');
  signal tb_cs_sel_i      : std_logic_vector(g_num_cs_select-1 downto 0) := (others=>'0');
  signal tb_load_i        : std_logic := '0';
  signal tb_sclk_divsel_i : std_logic_vector(2 downto 0) := (others=>'0');
  signal tb_dac_cs_n_o    : std_logic_vector(g_num_cs_select-1 downto 0);
  signal tb_dac_sclk_o    : std_logic;
  signal tb_dac_sdata_o   : std_logic;
  signal tb_busy_o        : std_logic;
  signal stop : boolean;
  signal s_data_o : std_logic_vector(g_num_data_bits+g_num_extra_bits-1 downto 0); 
  signal s_divider   : unsigned(11 downto 0);
  signal s_div_muxed : std_logic;
  signal s_bit_cnt   : std_logic_vector(g_num_data_bits+g_num_extra_bits+1 downto 0);
  signal s_dac_sclk  : std_logic;
  signal s_dac_data_o: std_logic;

  -- Shared variables used for coverage
  shared variable cp_rst_n_i : covPType;
  shared variable cp_busy_o  : covPType;

begin

  -- Unit Under Test
  UUT : entity work.gc_serial_dac
  generic map (
    g_num_data_bits => g_num_data_bits,
    g_num_extra_bits=> g_num_extra_bits,
    g_num_cs_select => g_num_cs_select,
    g_sclk_polarity => g_sclk_polarity)
  port map (
    clk_i          => tb_clk_i,
    rst_n_i        => tb_rst_n_i,
    value_i        => tb_value_i,
    cs_sel_i       => tb_cs_sel_i,
    load_i         => tb_load_i,
    sclk_divsel_i  => tb_sclk_divsel_i,
    dac_cs_n_o     => tb_dac_cs_n_o,
    dac_sclk_o     => tb_dac_sclk_o,
    dac_sdata_o    => tb_dac_sdata_o,
    busy_o         => tb_busy_o);

  -- Clock generation
	clk_proc : process
	begin
    while not stop loop
			tb_clk_i <= '1';
			wait for C_CLK_PERIOD/2;
			tb_clk_i <= '0';
			wait for C_CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

  -- Stimulus
  stim : process
    variable data : RandomPType;
	  variable ncycles : natural;
  begin
    while NOW < 4 ms loop
      -- when we are not busy, we sent data
      wait until (rising_edge(tb_clk_i) and tb_busy_o = '0');
	    tb_value_i       <= data.randSlv(g_num_data_bits);
      tb_load_i        <= data.randSlv(1)(1);
      tb_cs_sel_i      <= data.randSlv(g_num_cs_select);
      tb_sclk_divsel_i <= data.randSlv(3);
	    ncycles          := ncycles + 1;
	  end loop;
	  report "Number of simulation cycles = " & to_string(ncycles);
	  stop <= TRUE;
    report "Test PASS!";
	  wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                      Reproducing the RTL behavior                          --
  --------------------------------------------------------------------------------

  divider_sel : process (s_divider, tb_sclk_divsel_i)
  begin  -- process
    case tb_sclk_divsel_i is
      when "000"  => s_div_muxed <= s_divider(1);  
      when "001"  => s_div_muxed <= s_divider(2); 
      when "010"  => s_div_muxed <= s_divider(3); 
      when "011"  => s_div_muxed <= s_divider(4);
      when "100"  => s_div_muxed <= s_divider(5);
      when "101"  => s_div_muxed <= s_divider(6);
      when "110"  => s_div_muxed <= s_divider(7);
      when "111"  => s_div_muxed <= s_divider(8);
      when others => null;
    end case;
  end process;

  divider : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_load_i = '1' then
        s_divider <= (others => '0');
      elsif tb_busy_o = '1' then
        if s_div_muxed = '1' then
          s_divider <= (others => '0');
        else
          s_divider <= s_divider + 1;
        end if;
      elsif s_bit_cnt(s_bit_cnt'left) = '1' then
        s_divider <= (others => '0');
      end if;
    end if;
  end process;

  bit_counter : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_load_i = '1' and tb_busy_o = '0' then
        s_bit_cnt(0)                       <= '1';
        s_bit_cnt(s_bit_cnt'left downto 1) <= (others => '0');
      elsif tb_busy_o = '1' and to_integer(s_divider) = 0 and s_dac_sclk = '1' then
        s_bit_cnt(0)                       <= '0';
        s_bit_cnt(s_bit_cnt'left downto 1) <= s_bit_cnt(s_bit_cnt'left - 1 downto 0);
      end if;
    end if;
  end process;

  dac_sclk : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_dac_sclk <= '1';
      else
        if tb_load_i = '1' then
          s_dac_sclk <= '1';
        elsif s_div_muxed = '1' then
          s_dac_sclk <= not(s_dac_sclk);
        elsif s_bit_cnt(s_bit_cnt'left) = '1' then
          s_dac_sclk <= '1';
        end if;
      end if;
    end if;
  end process;
    
  data_out : process(tb_clk_i)
  begin
    if rising_edge(tb_clk_i) then 
      if tb_rst_n_i = '0' then
        s_data_o <= (others=>'0');
      else
        if (tb_load_i = '1' and tb_busy_o = '0') then
          s_data_o(g_num_data_bits-1 downto 0) <= tb_value_i;
          s_data_o(s_data_o'left downto g_num_data_bits) <= (others=>'0');
        elsif (tb_busy_o = '1' and s_dac_sclk = '0' and s_div_muxed = '1') then
          s_data_o(0) <= s_data_o(s_data_o'left);
          s_data_o(s_data_o'left downto 1) <= s_data_o(s_data_o'left-1 downto 0);
        end if;
      end if;
    end if;
  end process;

  s_dac_data_o <= s_data_o(s_data_o'left);

  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------

  process(tb_clk_i)
  begin
    if falling_edge(tb_clk_i) then
      if tb_rst_n_i = '1' then
        assert (s_dac_data_o = tb_dac_sdata_o)
          report "data mismatch" severity failure;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------

  -- sets up coverpoint bins
  init_coverage : process
  begin
    cp_rst_n_i.AddBins("Reset asserted", ONE_BIN);
    cp_busy_o.AddBins("DAC is not busy", ONE_BIN);
    wait;
  end process;

  -- sample coverpoints for reset
  sample_rst_i : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      wait until (rising_edge(tb_rst_n_i));
      cp_rst_n_i.ICover(to_integer(tb_rst_n_i = '1'));
    end loop;
  end process;

  -- sample coverpoints for busy
  sample_busy_o : process
  begin
    loop
      wait until rising_edge(tb_clk_i);
      cp_busy_o.ICover(to_integer(tb_busy_o='1'));
    end loop;
  end process;

  -- coverage report
  cover_report : process
  begin
    wait until stop;
    cp_rst_n_i.writebin;
    cp_busy_o.writebin;
  end process;

end tb;
