-------------------------------------------------------------------------------
-- Title      : Testbench for SPI Bus Master
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : tb_gc_simple_spi_master.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2021-12-13
-- Last update: 
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Testbench for a simple SPI master (bus-less). 
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011-2013 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_simple_spi_master is
  generic (
    g_seed           : natural;
    g_div_ratio_log2 : integer := 2;
    g_num_data_bits  : integer := 2);
end entity;

architecture tb of tb_gc_simple_spi_master is

  -- constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;

  -- signals
  signal tb_clk_sys_i  : std_logic;
  signal tb_rst_n_i    : std_logic;
  signal tb_cs_i       : std_logic := '0';
  signal tb_start_i    : std_logic := '0';
  signal tb_cpol_i     : std_logic := '0';
  signal tb_data_i     : std_logic_vector(g_num_data_bits - 1 downto 0) := (others=>'0');
  signal tb_ready_o    : std_logic;
  signal tb_data_o     : std_logic_vector(g_num_data_bits - 1 downto 0);
  signal tb_spi_cs_n_o : std_logic;
  signal tb_spi_sclk_o : std_logic;
  signal tb_spi_mosi_o : std_logic;
  signal tb_spi_miso_i : std_logic := '0';
  signal stop          : boolean;
  signal s_tick        : std_logic;
  signal s_div         : unsigned(11 downto 0);
  signal s_mosi        : std_logic;

  type t_state is (IDLE, TX_CS, TX_DAT1, TX_DAT2, TX_SCK1, TX_SCK2, TX_CS2, TX_GAP);
  signal s_state : t_state;
  signal s_cnt   : unsigned(4 downto 0) := (others=>'0');
  
  -- Shared variable used for FSM coverage  
  shared variable sv_cover : covPType;
    
  --------------------------------------------------------------------------------
  --                    Procedures used for fsm coverage                        --
  --------------------------------------------------------------------------------

  -- states
  procedure fsm_covadd_states (
    name  : in string;
    prev  : in t_state;
    curr  : in t_state;
    covdb : inout covPType) is
  begin
    covdb.AddCross ( name,
                   GenBin(t_state'pos(prev)),
                   GenBin(t_state'pos(curr)));
  end procedure;
    
  -- illegal 
  procedure fsm_covadd_illegal (
    name  : in string;
    covdb : inout covPType ) is
  begin
    covdb.AddCross(ALL_ILLEGAL,ALL_ILLEGAL);
  end procedure;

  -- collection
  procedure fsm_covcollect (
    signal reset : in std_logic;
    signal clk   : in std_logic;
    signal state : in t_state;
         covdb   : inout covPType) is
    variable v_state : t_state := IDLE; --t_state'left;
  begin
    wait until reset='1';
    loop
      v_state := state;
      wait until rising_edge(clk);
      covdb.ICover((t_state'pos(v_state), t_state'pos(state)));
    end loop;
  end procedure;

begin

  -- Unit Under Test
  UUT : entity work.gc_simple_spi_master
  generic map (
    g_div_ratio_log2 => g_div_ratio_log2,
    g_num_data_bits  => g_num_data_bits)
  port map (
    clk_sys_i  => tb_clk_sys_i,
    rst_n_i    => tb_rst_n_i,
    cs_i       => tb_cs_i,
    start_i    => tb_start_i,
    cpol_i     => tb_cpol_i,
    data_i     => tb_data_i,
    ready_o    => tb_ready_o,
    data_o     => tb_data_o,
    spi_cs_n_o => tb_spi_cs_n_o,
    spi_sclk_o => tb_spi_sclk_o,
    spi_mosi_o => s_mosi, 
    spi_miso_i => s_mosi); 

   -- Clock generation
	clk_sys_proc : process
	begin
    while not stop loop
			tb_clk_sys_i <= '1';
			wait for C_CLK_SYS_PERIOD/2;
			tb_clk_sys_i <= '0';
			wait for C_CLK_SYS_PERIOD/2;
		end loop;
		wait;
	end process clk_sys_proc;

  -- Reset generation
  tb_rst_n_i <= '0', '1' after 4*C_CLK_SYS_PERIOD;

  -- Slave clocks in the data on risigin SCLK edge
  tb_cpol_i <= '1';
    
  -- Stimulus
  stim : process
    variable ncycles : natural;
    variable data    : RandomPType;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while NOW < 4 ms loop
      wait until (rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1');
      tb_start_i <= data.randSlv(1)(1);
      tb_cs_i    <= data.randSlv(1)(1);
      ncycles    := ncycles + 1;
    end loop;
	  report "Number of simulation cycles = " & to_string(ncycles);
	  stop <= TRUE;
	  wait;
  end process stim;
  
  -- Stimulus for data  
  stim_data : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    while not stop loop
      wait until rising_edge(tb_ready_o);
      tb_data_i <= data.randSlv(g_num_data_bits);
      wait until rising_edge(tb_ready_o);
      ncycles   := ncycles + 1;
    end loop;
    wait;
  end process;

  -- processs to produce the tick needed for changing the states
  -- Simple clock divider like in the RTL code
  clk_divide : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '0' then
        s_div <= (others=>'0');
      else
        if (tb_start_i = '1' or s_tick = '1') then
          s_div <= (others=>'0');
        else
          s_div <= s_div + 1;
        end if;
      end if;
    end if;
  end process;

  s_tick <= s_div(g_div_ratio_log2);

  -- Describe the FSM
  fsm_descr : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i='0' then
        s_state <= IDLE;
        s_cnt <= (others=>'0');
      else
        case s_state is
          when IDLE => 
            s_cnt <= (others=>'0');
            if tb_start_i = '1' then 
              s_state <= TX_CS;
            end if;
                     
          when TX_CS => 
            if s_tick='1' then 
              s_state <=TX_DAT1; 
            end if;
                     
          when TX_DAT1 => 
            if s_tick='1' then 
              s_state <= TX_SCK1; 
            end if;
                     
          when TX_SCK1 => 
            if s_tick='1' then 
              s_state <= TX_DAT2;
              s_cnt <= s_cnt + 1;
            end if;
                     
          when TX_DAT2 => 
            if s_tick='1' then 
              s_state <= TX_SCK2; 
            end if;
                     
          when TX_SCK2 => 
            if s_tick='1' then
              if s_cnt=g_num_data_bits then
                s_state <= TX_CS2;
              else
                s_state <= TX_DAT1;
              end if;
            end if;
                     
          when TX_CS2 => 
            if s_tick='1' then 
              s_state <= TX_GAP; 
            end if;
                     
          when TX_GAP => 
            if s_tick='1' then 
              s_state <= IDLE; 
            end if;
                     
          when others =>
            null; 
        end case;
      end if;
    end if;
  end process;
    
  --------------------------------------------------------------------------------
  --                              Assertions                                    --
  --------------------------------------------------------------------------------
    
  process
  begin
    while not stop loop
      wait until s_state = TX_GAP;
      assert (tb_data_o = tb_data_i)
        report "Data mismatch" severity failure;
    end loop;
  end process;

  --------------------------------------------------------------------------------
  --                                Coverage                                    --
  --------------------------------------------------------------------------------

  process
  begin
    -- All possible legal changes
    fsm_covadd_states("IDLE   ->TX_CS  ", IDLE,    TX_CS,   sv_cover);
    fsm_covadd_states("TX_CS  ->TX_DAT1", TX_CS,   TX_DAT1, sv_cover);
    fsm_covadd_states("TX_DAT1->TX_SCK1", TX_DAT1, TX_SCK1, sv_cover);
    fsm_covadd_states("TX_SCK1->TX_DAT2", TX_SCK1, TX_DAT2, sv_cover);
    fsm_covadd_states("TX_DAT2->TX_SCK2", TX_DAT2, TX_SCK2, sv_cover);
    fsm_covadd_states("TX_SCK2->TX_DAT1", TX_SCK2, TX_DAT1, sv_cover);
    fsm_covadd_states("TX_SCK2->TX_CS2 ", TX_SCK2, TX_CS2,  sv_cover);
    fsm_covadd_states("TX_CS2 ->TX_GAP ", TX_CS2,  TX_GAP,  sv_cover);
    fsm_covadd_states("TX_GAP ->IDLE   ", TX_GAP,  IDLE,    sv_cover);
    -- we have also the case where we stay for many clocks in the same state
    fsm_covadd_states("IDLE   ->IDLE   ", IDLE,    IDLE,   sv_cover);
    fsm_covadd_states("TX_CS  ->TX_CS  ", TX_CS,   TX_CS, sv_cover);
    fsm_covadd_states("TX_DAT1->TX_DAT1", TX_DAT1, TX_DAT1, sv_cover);
    fsm_covadd_states("TX_SCK1->TX_SCK1", TX_SCK1, TX_SCK1, sv_cover);
    fsm_covadd_states("TX_DAT2->TX_DAT2", TX_DAT2, TX_DAT2, sv_cover);
    fsm_covadd_states("TX_SCK2->TX_SCK2", TX_SCK2, TX_SCK2, sv_cover);
    fsm_covadd_states("TX_CS2 ->TX_CS2 ", TX_CS2,  TX_CS2,  sv_cover);
    fsm_covadd_states("TX_GAP ->TX_GAP ", TX_GAP,  TX_GAP,    sv_cover);
    fsm_covadd_illegal("ILLEGAL        ", sv_cover);
    wait;
  end process;

  fsm_covcollect(tb_rst_n_i, tb_clk_sys_i, s_state,sv_cover);
    
  -- coverage report
  cov_report : process
  begin
    wait until stop ; 
    sv_cover.writebin;
  end process;


end tb;
