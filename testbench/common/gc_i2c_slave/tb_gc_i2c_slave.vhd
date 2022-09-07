-------------------------------------------------------------------------------
-- Title      : Testbench for I2C Slave Core
-- Project    : OHWR General Cores
-- URL        : http://www.ohwr.org/projects/general-cores
-------------------------------------------------------------------------------
-- File       : tb_gc_i2c_slave.vhd
-- Author(s)  : Konstantinos Blantos 
-- Company    : CERN (BE-CEM-EDL)
-- Created    : 2022-01-13
-- Last update: 
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for simple I2C slave interface, providing the basic 
-- low-level functionality of the I2C protocol.
--
-- The gc_i2c_slave module waits for a master to initiate a transfer via
-- a start condition. The address is sent next and if the address matches
-- the slave address set via the i2c_addr_i input, the addr_good_p_o output
-- is set. Based on the eighth bit of the first I2C transfer byte, the module
-- then starts shifting in or out each byte in the transfer, setting the
-- r/w_done_p_o output after each received/sent byte.
--
-- For master write (slave read) transfers, the received byte can be read at
-- the rx_byte_o output when the r_done_p_o pin is high. For master read (slave
-- write) transfers, the slave sends the byte at the tx_byte_i input, which
-- should be set when the w_done_p_o output is high, either after I2C address
-- reception, or a successful send of a previous byte.
--
-- dependencies:
--    OHWR general-cores library
--
-- references:
--    [1] The I2C bus specification, version 2.1, NXP Semiconductor, Jan. 2000
--        http://www.nxp.com/documents/other/39340011.pdf
-------------------------------------------------------------------------------
-- Copyright (c) 2013-2016 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
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

use work.gencores_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_gc_i2c_slave is
  generic (
    g_seed          : natural;
    g_gf_len        : natural := 0;
    g_auto_addr_ack : boolean := true);
end entity;

architecture tb of tb_gc_i2c_slave is

  -- Constants
  constant C_CLK_PERIOD         : time := 10 ns;
  constant C_CLK_QUARTER_PERIOD : time := 50 ns; --i2c clk quarter period
  constant C_MUL                : natural := 2; --i2c clk quarter period
  constant C_HALF               : natural := (C_CLK_QUARTER_PERIOD*C_MUL*2)/C_CLK_PERIOD;
  constant C_QUARTER            : natural := (C_CLK_QUARTER_PERIOD*C_MUL)/C_CLK_PERIOD;

  -- Signals
  signal tb_clk_i            : std_logic;
  signal tb_rst_n_i          : std_logic;
  signal tb_scl_i            : std_logic := '1';
  signal tb_scl_o            : std_logic;
  signal tb_scl_en_o         : std_logic;
  signal tb_sda_i            : std_logic := '1';
  signal tb_sda_o            : std_logic;
  signal tb_sda_en_o         : std_logic;
  signal tb_i2c_addr_i       : std_logic_vector(6 downto 0) := (others=>'0');
  signal tb_ack_i            : std_logic := '0';
  signal tb_tx_byte_i        : std_logic_vector(7 downto 0) := (others=>'0');
  signal tb_rx_byte_o        : std_logic_vector(7 downto 0);
  signal tb_i2c_sta_p_o      : std_logic;
  signal tb_i2c_sto_p_o      : std_logic;
  signal tb_addr_good_p_o    : std_logic;
  signal tb_r_done_p_o       : std_logic;
  signal tb_w_done_p_o       : std_logic;
  signal tb_op_o             : std_logic;
  -- used for fsm
  signal s_inhibit           : std_logic;
  signal s_scl_synced        : std_logic;
  signal s_sda_synced        : std_logic;
  signal s_sta_p             : std_logic;
  signal s_sto_p             : std_logic;
  signal s_scl_deglitched    : std_logic;
  signal s_sda_deglitched    : std_logic;
  signal s_scl_deglitched_d0 : std_logic;
  signal s_sda_deglitched_d0 : std_logic;
  signal s_scl_r_edge_p      : std_logic;
  signal s_scl_f_edge_p      : std_logic;
  signal s_sda_f_edge_p      : std_logic;
  signal s_sda_r_edge_p      : std_logic;
  signal s_bit_cnt           : unsigned(2 downto 0);
  signal s_rxsr              : std_logic_vector(7 downto 0);
  signal s_txsr              : std_logic_vector(7 downto 0);
  signal s_mst_acked         : std_logic;
  signal stop                : boolean := FALSE;

  type t_state is 
  (
    IDLE,            -- idle
    ADDR,            -- shift in I2C address bits
    ADDR_ACK,        -- ACK/NACK to I2C address
    RD,              -- shift in byte to read
    RD_ACK,          -- ACK/NACK to received byte
    WR_LOAD_TXSR,    -- load byte to send via I2C
    WR,              -- shift out byte
    WR_ACK           -- get ACK/NACK from master
  );

  signal s_state : t_state;

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
           covdb : inout covPType) is
    variable v_state : t_state := t_state'left;
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
  UUT : entity work.gc_i2c_slave
  generic map (
    g_gf_len        => g_gf_len,
    g_auto_addr_ack => g_auto_addr_ack)
  port map (
    clk_i         => tb_clk_i,
    rst_n_i       => tb_rst_n_i,
    scl_i         => tb_scl_i,
    scl_o         => tb_scl_o,
    scl_en_o      => tb_scl_en_o,
    sda_i         => tb_sda_i,
    sda_o         => tb_sda_o,
    sda_en_o      => tb_sda_en_o,
    i2c_addr_i    => tb_i2c_addr_i,
    ack_i         => tb_ack_i,
    tx_byte_i     => tb_tx_byte_i,
    rx_byte_o     => tb_rx_byte_o,
    i2c_sta_p_o   => tb_i2c_sta_p_o,
    i2c_sto_p_o   => tb_i2c_sto_p_o,
    addr_good_p_o => tb_addr_good_p_o,
    r_done_p_o    => tb_r_done_p_o,
    w_done_p_o    => tb_w_done_p_o,
    op_o          => tb_op_o);

  -- Clock generation
  clk_in_proc : process
  begin
    while stop = FALSE loop
      tb_clk_i <= '1';
      wait for C_CLK_PERIOD/2;
      tb_clk_i <= '0';
      wait for C_CLK_PERIOD/2;
    end loop;
    wait;
  end process;
	
  -- Reset generation
  tb_rst_n_i <= '0', '1' after 4 * C_CLK_PERIOD;

  -- Process which contains the testing process
  test : process
    
    -- wait half clock
    procedure i2c_wait_half_clk is
    begin
      for i in 0 to C_HALF loop
        wait until rising_edge(tb_clk_i);
      end loop;
    end procedure;

    -- wait quarter clock
    procedure i2c_wait_quarter_clk is
    begin
      for i in 0 to C_QUARTER loop
        wait until rising_edge(tb_clk_i);
      end loop;
    end procedure;

    -- i2c send bit
    procedure i2c_send_bit (
      constant c_bit : in std_logic) is
    begin
      tb_scl_i <= '0';
      if c_bit = '0' then
        tb_sda_i <= '0';
      else
        tb_sda_i <= '1';
      end if;
      i2c_wait_quarter_clk;
      tb_scl_i <= '1';
      i2c_wait_half_clk;
      tb_scl_i <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c receive bit
    procedure i2c_receive_bit (
      variable v_bit : out std_logic) is
    begin
      tb_scl_i   <= '0';
      tb_sda_i   <= '1';
      i2c_wait_quarter_clk;
      tb_scl_i   <= '1';
      i2c_wait_quarter_clk;
      if tb_sda_i = '0' then
        v_bit := '0';
      else
        v_bit := '1';
      end if;
      i2c_wait_quarter_clk;
      tb_scl_i   <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c send byte
    procedure i2c_send_byte (
      constant c_byte : in std_logic_vector(7 downto 0)) is
    begin
      for i in 7 downto 0 loop
        i2c_send_bit(c_byte(i));
      end loop;
    end procedure;

    -- i2c send address
    procedure i2c_send_address (
      constant c_addr : in std_logic_vector(6 downto 0)) is
    begin
      for i in 6 downto 0 loop
        i2c_send_bit(c_addr(i));
      end loop;
    end procedure;

    -- i2c receive byte
    procedure i2c_receive_byte (
      signal s_byte  : out std_logic_vector(7 downto 0)) is
      variable v_bit : std_logic;
      variable v_acc : std_logic_vector(7 downto 0) := (others => '0');
    begin
      for i in 7 downto 0 loop
        i2c_receive_bit(v_bit);
        v_acc(i) := v_bit;
      end loop;
      s_byte <= v_acc;
    end procedure;

    -- i2c start
    procedure i2c_start is
    begin
      tb_scl_i <= '1';
      tb_sda_i <= '0';
      i2c_wait_half_clk;
      tb_scl_i <= '1';
      i2c_wait_quarter_clk;
      tb_scl_i <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c stop
    procedure i2c_stop is
    begin
      tb_scl_i <= '0';
      tb_sda_i <= '0';
      i2c_wait_quarter_clk;
      tb_scl_i <= '1';
      i2c_wait_quarter_clk;
      tb_sda_i <= '1';
      i2c_wait_half_clk;
      i2c_wait_half_clk;
    end procedure;

    -- i2c set write
    procedure i2c_set_write is
    begin
      i2c_send_bit('0');
    end procedure;

    -- i2c set read
    procedure i2c_set_read is
    begin
      i2c_send_bit('1');
    end procedure;

    -- i2c read acknowledge
    procedure i2c_read_ack (
      signal s_ack : out std_logic) is
    begin
      tb_scl_i <= '0';
      tb_sda_i <= '1';
      i2c_wait_quarter_clk;
      tb_scl_i <= '1';
      if tb_ack_i = '0' then
        s_ack <= '1';
      else
        s_ack <= '0';
      end if;
      i2c_wait_half_clk;
      tb_scl_i <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c write acknowledge
    procedure i2c_write_nack is
    begin
      tb_scl_i <= '0';
      tb_sda_i <= '1';
      i2c_wait_quarter_clk;
      tb_scl_i <= '1';
      i2c_wait_half_clk;
      tb_scl_i <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c write acknowledge
    procedure i2c_write_ack is
    begin
      tb_scl_i <= '0';
      tb_sda_i <= '0';
      i2c_wait_quarter_clk;
      tb_scl_i <= '1';
      i2c_wait_half_clk;
      tb_scl_i <= '0';
      i2c_wait_quarter_clk;
    end procedure;

    -- i2c write process
    procedure i2c_write (
      constant c_addr : in std_logic_vector(6 downto 0);
      constant c_data : in std_logic_vector(7 downto 0)) is
    begin
      i2c_start;
      i2c_send_address(c_addr);
      i2c_set_write;
      i2c_read_ack(tb_ack_i);
      if tb_ack_i = '0' then
        i2c_stop;
        return;
      end if;
      i2c_send_byte(c_data);
      i2c_read_ack(tb_ack_i);
      i2c_stop;
    end procedure;

    -- i2c write bytes
    procedure i2c_write_bytes (
      constant c_addr      : in std_logic_vector(6 downto 0);
      constant c_nof_bytes : in integer range 0 to 1023) is
      variable v_data      : std_logic_vector(7 downto 0) := (others => '0');
    begin
      i2c_start;
      i2c_send_address(c_addr);
      i2c_set_write;
      i2c_read_ack(tb_ack_i);
      if tb_ack_i = '0' then
        i2c_stop;
        return;
      end if;
      tb_ack_i <= '0';
      for i in 0 to c_nof_bytes-1 loop
        i2c_send_byte(std_logic_vector(to_unsigned(i, 8)));
        i2c_read_ack(tb_ack_i);
        if tb_ack_i = '0' then
          i2c_stop;
          return;
        end if;
        tb_ack_i <= '0';
      end loop;
      i2c_stop;
    end procedure;

    -- i2c read process
    procedure i2c_read (
      constant c_addr : in  std_logic_vector(6 downto 0);
      signal   s_data : out std_logic_vector(7 downto 0)) is
    begin
      i2c_start;
      i2c_send_address(c_addr);
      i2c_set_read;
      i2c_read_ack(tb_ack_i);
      if tb_ack_i = '0' then
        i2c_stop;
        return;
      end if;
      tb_ack_i <= '0';
      i2c_receive_byte(s_data);
      i2c_write_nack;
      i2c_stop;
    end procedure;

    -- i2c ready bytes
    procedure i2c_read_bytes (
      constant c_addr      : in  std_logic_vector(6 downto 0);
      constant c_nof_bytes : in  integer range 0 to 1023;
      signal   s_data      : out std_logic_vector(7 downto 0)) is
    begin
      i2c_start;
      i2c_send_address(c_addr);
      i2c_set_read;
      i2c_read_ack(tb_ack_i);
      if tb_ack_i = '0' then
        i2c_stop;
        return;
      end if;
      for i in 0 to c_nof_bytes-1 loop
        i2c_receive_byte(s_data);
        if i < c_nof_bytes-1 then
          i2c_write_ack;
        else
          i2c_write_nack;
        end if;
      end loop;
      i2c_stop;
    end procedure i2c_read_bytes;
  
  begin

    tb_i2c_addr_i <= "1010000";
    tb_scl_i <= '1';
    tb_sda_i <= '1';
    report "Testing a single write";
    i2c_write("1010000", "11111111");
    assert (tb_rx_byte_o = "11111111") 
      report "wrong data" severity failure;

    report "Testing a single write";
    i2c_write(tb_i2c_addr_i, "11111010");
    assert (tb_rx_byte_o = "11111010")
      report "wrong data" severity failure;

    report "Testing repeated writes";
    for i in 0 to 127 loop
      i2c_write(tb_i2c_addr_i, std_logic_vector(to_unsigned(i,8)));
      assert i = to_integer(unsigned(tb_rx_byte_o))
        report "writing test: " & integer'image(i) & "not passed"
        severity failure;
    end loop;

    report "Testing repeated reads";
    for i in 0 to 127 loop
      tb_tx_byte_i <= std_logic_vector(to_unsigned(i,8));
      i2c_read(tb_i2c_addr_i,tb_tx_byte_i);
    end loop;

    wait until rising_edge(tb_clk_i);
    stop <= true;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                          Coverage                                          --
  --------------------------------------------------------------------------------
  
  -- First, synchronize the SCL signal in the clk_i domain
  cmp_sync_scl : gc_sync_ffs
    generic map
    (
      g_sync_edge => "positive"
    )
    port map
    (
      clk_i    => tb_clk_i,
      rst_n_i  => tb_rst_n_i,
      data_i   => tb_scl_i,
      synced_o => s_scl_synced
    );

  -- Generate deglitched SCL signal
  cmp_scl_deglitch : gc_glitch_filt
    generic map
    (
      g_len => g_gf_len
    )
    port map
    (
      clk_i   => tb_clk_i,
      rst_n_i => tb_rst_n_i,
      dat_i   => s_scl_synced,
      dat_o   => s_scl_deglitched
    );

  -- and create a delayed version of this signal, together with one-tick-long
  -- falling-edge detection signal
  p_scl_degl_d0 : process(tb_clk_i) is
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_scl_deglitched_d0 <= '0';
        s_scl_f_edge_p      <= '0';
        s_scl_r_edge_p      <= '0';
      else
        s_scl_deglitched_d0 <= s_scl_deglitched;
        s_scl_f_edge_p      <= (not s_scl_deglitched) and s_scl_deglitched_d0;
        s_scl_r_edge_p      <= s_scl_deglitched and (not s_scl_deglitched_d0);
      end if;
    end if;
  end process p_scl_degl_d0;

  -- Synchronize SDA signal in clk_i domain
  cmp_sda_sync : gc_sync_ffs
    generic map
    (
      g_sync_edge => "positive"
    )
    port map
    (
      clk_i    => tb_clk_i,
      rst_n_i  => tb_rst_n_i,
      data_i   => tb_sda_i,
      synced_o => s_sda_synced
    );

  -- Generate deglitched SDA signal
  cmp_sda_deglitch : gc_glitch_filt
    generic map
    (
      g_len => g_gf_len
    )
    port map
    (
      clk_i   => tb_clk_i,
      rst_n_i => tb_rst_n_i,
      dat_i   => s_sda_synced,
      dat_o   => s_sda_deglitched
    );

  -- and create a delayed version of this signal, together with one-tick-long
  -- falling- and rising-edge detection signals
  p_sda_deglitched_d0 : process(tb_clk_i) is
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_sda_deglitched_d0 <= '0';
        s_sda_f_edge_p      <= '0';
        s_sda_r_edge_p      <= '0';
      else
        s_sda_deglitched_d0 <= s_sda_deglitched;
        s_sda_f_edge_p      <= (not s_sda_deglitched) and s_sda_deglitched_d0;
        s_sda_r_edge_p      <= s_sda_deglitched and (not s_sda_deglitched_d0);
      end if;
    end if;
  end process p_sda_deglitched_d0;

  -- First the process to set the start and stop conditions as per I2C standard
  p_sta_sto : process (tb_clk_i) is
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_sta_p <= '0';
        s_sto_p <= '0';
      else
        s_sta_p <= s_sda_f_edge_p and s_scl_deglitched;
        s_sto_p <= s_sda_r_edge_p and s_scl_deglitched;
      end if;
    end if;
  end process p_sta_sto;

  -- FSM 
  fsm: process (tb_clk_i) is
  begin
    if rising_edge(tb_clk_i) then
      if tb_rst_n_i = '0' then
        s_state         <= IDLE;
        s_inhibit       <= '0';
        s_bit_cnt       <= (others => '0');
        s_rxsr          <= (others => '0');
        s_txsr          <= (others => '0');
        s_mst_acked     <= '0';

      elsif (s_sta_p = '1') or (s_sto_p = '1') then
        s_state   <= IDLE;
        s_inhibit <= '0';
      
      else
        case s_state is
          when IDLE =>
            s_bit_cnt       <= (others => '0');
            s_mst_acked     <= '0';
            if s_scl_f_edge_p = '1' and s_inhibit = '0' then
              s_state <= ADDR;
            end if;

          when ADDR =>
            if s_scl_r_edge_p = '1' then
              s_rxsr    <= s_rxsr(6 downto 0) & s_sda_deglitched;
              s_bit_cnt <= s_bit_cnt + 1;
            end if;
            
            if s_scl_f_edge_p = '1' then
              if s_bit_cnt = 0 then
                if (s_rxsr(7 downto 1) = tb_i2c_addr_i) then
                  s_state         <= ADDR_ACK;
                else
                  s_inhibit <= '1';
                  s_state   <= IDLE;
                end if;
              end if;
            end if;

          when ADDR_ACK =>
           if s_scl_f_edge_p = '1' then
              if (g_auto_addr_ack = TRUE) or (tb_ack_i = '1') then
                if (s_rxsr(0) = '0') then
                  s_state <= RD;
                else
                  s_state <= WR_LOAD_TXSR;
                end if;
              else
                s_state <= IDLE;
              end if;
            end if;

          when RD =>

            if s_scl_r_edge_p = '1' then
              s_rxsr    <= s_rxsr(6 downto 0) & s_sda_deglitched;
              s_bit_cnt <= s_bit_cnt + 1;
            end if;

            if s_scl_f_edge_p = '1' then
              if s_bit_cnt = 0 then
                s_state      <= RD_ACK;
              end if;
            end if;

          when RD_ACK =>

            if s_scl_f_edge_p = '1' then
              if tb_ack_i = '1' then
                s_state <= RD;
              else
                s_state <= IDLE;
              end if;
            end if;
          
          when WR_LOAD_TXSR =>
            s_txsr  <= tb_tx_byte_i;
            s_state <= WR;
          
          when WR =>

            if s_scl_r_edge_p = '1' then
              s_bit_cnt <= s_bit_cnt + 1;
            end if;

            if s_scl_f_edge_p = '1' then
              s_txsr <= s_txsr(6 downto 0) & '0';

              if s_bit_cnt = 0 then
                s_state      <= WR_ACK;
              end if;
            end if;

          when WR_ACK =>
            
            if s_scl_r_edge_p = '1' then
              if s_sda_deglitched = '0' then
                s_mst_acked <= '1';
              else
                s_mst_acked <= '0';
              end if;
            end if;

            if s_scl_f_edge_p = '1' then
              if s_mst_acked = '1' then
                s_state <= WR_LOAD_TXSR;
              else
                s_state <= IDLE;
              end if;
            end if;

          when others =>
            s_state <= IDLE;

        end case;
      end if;
    end if;
  end process;

  process
  begin
    -- all possible legal state changes
    fsm_covadd_states("IDLE         -> ADDR        ",IDLE         ,ADDR        ,sv_cover);
    fsm_covadd_states("ADDR         -> IDLE        ",ADDR         ,IDLE        ,sv_cover);
    fsm_covadd_states("ADDR         -> ADDR_ACK    ",ADDR         ,ADDR_ACK    ,sv_cover);
    fsm_covadd_states("ADDR_ACK     -> IDLE        ",ADDR_ACK     ,IDLE        ,sv_cover);
    fsm_covadd_states("ADDR_ACK     -> RD          ",ADDR_ACK     ,RD          ,sv_cover);
    fsm_covadd_states("ADDR_ACK     -> WR_LOAD_TXSR",ADDR_ACK     ,WR_LOAD_TXSR,sv_cover);
    fsm_covadd_states("RD           -> RD_ACK      ",RD           ,RD_ACK      ,sv_cover);
    fsm_covadd_states("RD_ACK       -> RD          ",RD_ACK       ,RD          ,sv_cover);
    fsm_covadd_states("RD_ACK       -> IDLE        ",RD_ACK       ,IDLE        ,sv_cover);
    fsm_covadd_states("WR_LOAD_TXSR -> WR          ",WR_LOAD_TXSR ,WR          ,sv_cover);
    fsm_covadd_states("WR           -> WR_ACK      ",WR           ,WR_ACK      ,sv_cover);
    fsm_covadd_states("WR_ACK       -> WR_LOAD_TXSR",WR_ACK       ,WR_LOAD_TXSR,sv_cover);
    fsm_covadd_states("WR_ACK       -> IDLE        ",WR_ACK       ,IDLE        ,sv_cover);
    -- when current and next state is the same
    fsm_covadd_states("IDLE         -> IDLE        ",IDLE        ,IDLE        ,sv_cover);
    fsm_covadd_states("ADDR         -> ADDR        ",ADDR        ,ADDR        ,sv_cover);
    fsm_covadd_states("ADDR_ACK     -> ADDR_ACK    ",ADDR_ACK    ,ADDR_ACK    ,sv_cover);
    fsm_covadd_states("RD           -> RD          ",RD          ,RD          ,sv_cover);
    fsm_covadd_states("RD_ACK       -> RD_ACK      ",RD_ACK      ,RD_ACK      ,sv_cover);
    fsm_covadd_states("WR           -> WR          ",WR          ,WR          ,sv_cover);
    fsm_covadd_states("WR_ACK       -> WR_ACK      ",WR_ACK      ,WR_ACK      ,sv_cover);
    -- illegal states
    fsm_covadd_illegal("ILLEGAL",sv_cover);
    wait;
  end process;
    
  -- collect the cov bins
  fsm_covcollect(tb_rst_n_i, tb_clk_i, s_state, sv_cover);
 
  -- coverage report
  cov_report : process
  begin
      wait until stop;
      sv_cover.writebin;
      report "Test PASS!";
  end process;

end tb;
