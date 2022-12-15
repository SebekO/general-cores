--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_wb_slave_adapter
--
-- author: Konstantinos Blantos <Konstantinos.Blantos@cern.ch>
--
-- description:
--   universal "adapter"
--   pipelined <> classic
--   word-aligned/byte-aligned address
--  Testbench for Wishbone Slave Adapter
--
--------------------------------------------------------------------------------
-- Copyright CERN 2011-2018
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_wb_slave_adapter              --
--=============================================================================

entity tb_wb_slave_adapter is
  generic (
    g_seed               : natural;
    g_master_use_struct  : boolean := TRUE;
    g_master_mode        : t_wishbone_interface_mode := PIPELINED;
    g_master_granularity : t_wishbone_address_granularity := BYTE;
    g_slave_use_struct   : boolean := TRUE;
    g_slave_mode         : t_wishbone_interface_mode := CLASSIC;
    g_slave_granularity  : t_wishbone_address_granularity:=BYTE);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_wb_slave_adapter is

  -- Constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;

  -- Signal
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_sl_adr_i  : std_logic_vector(c_wishbone_address_width-1 downto 0) := cc_dummy_address;
  signal tb_sl_dat_i  : std_logic_vector(c_wishbone_data_width-1 downto 0)    := cc_dummy_data;
  signal tb_sl_sel_i  : std_logic_vector(c_wishbone_data_width/8-1 downto 0)  := cc_dummy_sel;
  signal tb_sl_cyc_i  : std_logic                                             := '0';
  signal tb_sl_stb_i  : std_logic                                             := '0';
  signal tb_sl_we_i   : std_logic                                             := '0';
  signal tb_sl_dat_o  : std_logic_vector(c_wishbone_data_width-1 downto 0);
  signal tb_sl_err_o  : std_logic;
  signal tb_sl_rty_o  : std_logic;
  signal tb_sl_ack_o  : std_logic;
  signal tb_sl_stall_o: std_logic;
  signal tb_slave_i   : t_wishbone_slave_in                                   := cc_dummy_slave_in;
  signal tb_slave_o   : t_wishbone_slave_out;
  signal tb_ma_adr_o  : std_logic_vector(c_wishbone_address_width-1 downto 0);
  signal tb_ma_dat_o  : std_logic_vector(c_wishbone_data_width-1 downto 0);
  signal tb_ma_sel_o  : std_logic_vector(c_wishbone_data_width/8-1 downto 0);
  signal tb_ma_cyc_o  : std_logic;
  signal tb_ma_stb_o  : std_logic;
  signal tb_ma_we_o   : std_logic;
  signal tb_ma_dat_i  : std_logic_vector(c_wishbone_data_width-1 downto 0)    := cc_dummy_data;
  signal tb_ma_err_i  : std_logic                                             := '0';
  signal tb_ma_rty_i  : std_logic                                             := '0';
  signal tb_ma_ack_i  : std_logic                                             := '0';
  signal tb_ma_stall_i: std_logic                                             := '0';
  signal tb_master_i  : t_wishbone_master_in                                  := cc_dummy_slave_out;
  signal tb_master_o  : t_wishbone_master_out;
  signal stop : boolean;

  --used to describe P2C behavior
  signal tb_master_in_ack_d1 : std_logic;
  signal tb_master_in_err_d1 : std_logic;
  signal tb_master_in_rty_d1 : std_logic;
  signal s_master_i_ack      : std_logic;
  signal s_master_i_err      : std_logic;
  signal s_master_i_rty      : std_logic;

  --used to describe C2P behavior
  signal s_idle     : std_logic := '1';
  signal s_wait_ack : std_logic := '0';

  -- Functions
  function f_num_byte_address_bits
    return integer is
  begin
    case c_wishbone_data_width is
      when 8      => return 0;
      when 16     => return 1;
      when 32     => return 2;
      when 64     => return 3;
      when others =>
        report "wb_slave_adapter: invalid c_wishbone_data_width (we support 8, 16, 32 and 64)" severity failure;
    end case;
    return 0;
  end function f_num_byte_address_bits;

  function f_zeros(size : integer)
    return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(0, size));
  end function f_zeros;

begin

  --Unit Under Test
  UUT : entity work.wb_slave_adapter
  generic map (
    g_master_use_struct    => g_master_use_struct,
      g_master_mode        => g_master_mode,
      g_master_granularity => g_master_granularity,
      g_slave_use_struct   => g_slave_use_struct,
      g_slave_mode         => g_slave_mode,
      g_slave_granularity  => g_slave_granularity)
  port map (
      clk_sys_i   => tb_clk_sys_i,
      rst_n_i     => tb_rst_n_i,
      sl_adr_i    => tb_sl_adr_i,
      sl_dat_i    => tb_sl_dat_i,
      sl_sel_i    => tb_sl_sel_i,
      sl_cyc_i    => tb_sl_cyc_i,
      sl_stb_i    => tb_sl_stb_i,
      sl_we_i     => tb_sl_we_i,
      sl_dat_o    => tb_sl_dat_o,
      sl_err_o    => tb_sl_err_o,
      sl_rty_o    => tb_sl_rty_o,
      sl_ack_o    => tb_sl_ack_o,
      sl_stall_o  => tb_sl_stall_o,
      slave_i     => tb_slave_i,
      slave_o     => tb_slave_o,
      ma_adr_o    => tb_ma_adr_o,
      ma_dat_o    => tb_ma_dat_o,
      ma_sel_o    => tb_ma_sel_o,
      ma_cyc_o    => tb_ma_cyc_o,
      ma_stb_o    => tb_ma_stb_o,
      ma_we_o     => tb_ma_we_o,
      ma_dat_i    => tb_ma_dat_i,
      ma_err_i    => tb_ma_err_i,
      ma_rty_i    => tb_ma_rty_i,
      ma_ack_i    => tb_ma_ack_i,
      ma_stall_i  => tb_ma_stall_i,
      master_i    => tb_master_i,
      master_o    => tb_master_o);

  --clock/reset process
  sys_clk : process
  begin
    while (NOW < 1 ms) loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process;

  tb_rst_n_i <= '0', '1' after 2 * C_CLK_SYS_PERIOD;

  --Stimulus
  slave_stim_use_struct : if (g_slave_use_struct = TRUE) generate
  process
      variable data    : RandomPType;
      variable ncycles : natural;

  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    while (NOW < 1 ms) loop
      wait until (rising_edge (tb_clk_sys_i) and tb_rst_n_i = '1');
        tb_slave_i.adr <= data.randSlv(32);
        tb_slave_i.sel <= data.randSlv(4);
        tb_slave_i.we  <= data.randSlv(1)(1);
        tb_slave_i.dat <= data.randSlv(32);
        tb_slave_i.cyc <= data.randSlv(1)(1);
        tb_slave_i.stb <= data.randSlv(1)(1);
        ncycles        := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    wait;
  end process;
  end generate;

  slave_stim_no_use_struct : if (g_slave_use_struct = FALSE) generate
  process
      variable data    : RandomPType;
      variable ncycles : natural;
  begin
    while (NOW < 1 ms) loop
      data.InitSeed(g_seed);
      wait until (rising_edge (tb_clk_sys_i) and tb_rst_n_i = '1');
        tb_sl_adr_i    <= data.randSlv(32);
        tb_sl_dat_i    <= data.randSlv(32);
        tb_sl_sel_i    <= data.randSlv(4);
        tb_sl_cyc_i    <= data.randSlv(1)(1);
        tb_sl_stb_i    <= data.randSlv(1)(1);
        tb_sl_we_i     <= data.randSlv(1)(1);
        ncycles        := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= TRUE;
    wait;
  end process;
  end generate;

  -- Another stimulus for master side in order not to have the same seed
  master_stim_use_struct : if (g_master_use_struct = TRUE) generate
  process
      variable data    : RandomPType;
      variable ncycles : natural;
  begin
    while (NOW < 1 ms) loop
      data.InitSeed(g_seed);
      wait until (rising_edge (tb_clk_sys_i) and tb_rst_n_i = '1');
        tb_master_i.dat   <= data.randSlv(32);
        tb_master_i.ack   <= data.randSlv(1)(1);
        tb_master_i.err   <= data.randSlv(1)(1);
        tb_master_i.rty   <= data.randSlv(1)(1);
        tb_master_i.stall <= data.randSlv(1)(1);
        ncycles           := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process;
  end generate;

  master_stim_no_use_struct : if (g_master_use_struct = FALSE) generate
  process
      variable data    : RandomPType;
      variable ncycles : natural;
  begin
    while (NOW < 1 ms) loop
      data.InitSeed(g_seed);
      wait until (rising_edge (tb_clk_sys_i) and tb_rst_n_i = '1');
        tb_ma_dat_i   <= data.randSlv(32);
        tb_ma_err_i   <= data.randSlv(1)(1);
        tb_ma_rty_i   <= data.randSlv(1)(1);
        tb_ma_ack_i   <= data.randSlv(1)(1);
        tb_ma_stall_i <= data.randSlv(1)(1);
        ncycles       := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process;
  end generate;

  P2C_stim : if (g_slave_mode = PIPELINED and g_master_mode = CLASSIC) generate
  process (tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then --delay for one clock cycle
      tb_master_in_ack_d1 <= tb_master_i.ack;
      tb_master_in_err_d1 <= tb_master_i.err;
      tb_master_in_rty_d1 <= tb_master_i.rty;
    end if;
    s_master_i_ack <= tb_master_i.ack and not tb_master_in_ack_d1; --to create the one clk pulse
    s_master_i_err <= tb_master_i.err and not tb_master_in_err_d1;
    s_master_i_rty <= tb_master_i.rty and not tb_master_in_rty_d1;
  end process;
  end generate;

  master_i_assign : if (g_master_use_struct = FALSE) generate
    tb_master_i <= (tb_ma_ack_i,
                    tb_ma_err_i,
                    tb_ma_rty_i,
                    tb_ma_stall_i,
                    tb_ma_dat_i);
  end generate;

  slave_i_assign : if (g_slave_use_struct = FALSE) generate
    tb_slave_i <= (tb_sl_cyc_i,
                   tb_sl_stb_i,
                   tb_sl_adr_i,
                   tb_sl_sel_i,
                   tb_sl_we_i,
                   tb_sl_dat_i);
  end generate;


  -------------------------------------------------------------------------------------
  --                                  Assertions                                     --
  -------------------------------------------------------------------------------------

  -- Be sure to insert the right values for the generics
  assert (g_master_use_struct = FALSE or g_master_use_struct = TRUE)
    report "g_master_use_struct should be BOOLEAN" severity failure;

  assert (g_slave_use_struct = FALSE or g_slave_use_struct = TRUE)
    report "g_slave_use_struct should be BOOLEAN" severity failure;

  -- Checking the addresses of slave_in, master_out for different cases
  check_address : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '0' then

        if g_master_granularity = g_slave_granularity then
          assert (tb_master_o.adr = tb_slave_i.adr)
            report "wrong address with equal granularity" severity failure;

        elsif (g_master_granularity = BYTE) then
          assert (tb_master_o.adr <= tb_slave_i.adr(c_wishbone_address_width-f_num_byte_address_bits-1 downto 0)
                    & f_zeros(f_num_byte_address_bits))
            report "wrong address when g_master_granularity = BYTE" severity failure;

        else
          assert (tb_master_o.adr <= f_zeros(f_num_byte_address_bits)
                   & tb_slave_i.adr(c_wishbone_address_width-1 downto f_num_byte_address_bits))
            report "wrong address" severity failure;

        end if;
     end if;
    end if;
  end process;


  -- Checking slave_out and master_in with different modes
  P2C : if (g_slave_mode = PIPELINED and g_master_mode = CLASSIC)   generate
  process (tb_clk_sys_i)
  begin
    if (rising_edge(tb_clk_sys_i) and tb_rst_n_i='1') then

      assert (tb_master_o.stb = tb_slave_i.stb)
        report "P2C: mismatch stb"
        severity failure;

      if (tb_slave_i.cyc = '0') then
        assert (tb_slave_o.stall = '0')
          report "P2C: slave out stall is HIGH"
          severity failure;
      else
        assert (tb_slave_o.stall = not tb_master_i.ack)
          report "P2C: wrong stall"
          severity failure;
      end if;

      assert (tb_slave_o.ack = s_master_i_ack)
        report "P2C: wrong ack"
        severity failure;

      assert (tb_slave_o.err = s_master_i_err)
        report "P2C: wrong err"
        severity failure;

      assert (tb_slave_o.rty = s_master_i_rty)
        report "P2C: wrong rty"
        severity failure;

    end if;
  end process;
  end generate;

  C2P : if (g_slave_mode = CLASSIC   and g_master_mode = PIPELINED) generate
    type t_fsm_state is (IDLE, WAIT4ACK);
    signal fsm_state : t_fsm_state := IDLE;
  begin
  process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '0' then
        fsm_state <= IDLE;
        s_idle <= '0';
        s_wait_ack <= '0';
      else
        case fsm_state is

          when IDLE =>
            s_idle <= '1';
            if (tb_slave_i.stb = '1' and tb_slave_i.cyc = '1') and
               (tb_master_i.stall = '0' and tb_master_i.ack = '0' and tb_master_i.rty = '0') then
              fsm_state <= WAIT4ACK;
              s_idle <= '0';
            end if;
          when WAIT4ACK =>
            s_wait_ack <= '1';
            if (tb_slave_i.stb = '0' and tb_slave_i.cyc = '0') or
               (tb_master_i.ack = '1' or tb_master_i.err = '1' or tb_master_i.rty = '1') then
              fsm_state <= IDLE;
              s_wait_ack <= '0';
            end if;

          end case;
      end if;

      assert (tb_slave_o.ack = tb_master_i.ack)
        report "C2P: mismatch ack"
        severity failure;

      assert (tb_slave_o.err = tb_master_i.err)
        report "C2P: mismatch err"
        severity failure;

      assert (tb_slave_o.rty = tb_master_i.rty)
        report "C2P: mismatch rty"
        severity failure;

      assert (tb_slave_o.stall = '0')
        report "C2P: stall is HIGH"
        severity failure;


      if (s_idle) then

        assert (tb_master_o.stb = tb_slave_i.stb)
          report "C2P: stb mismatch when IDLE"
          severity failure;

      elsif (s_wait_ack) then

        assert (tb_master_o.stb = '0')
          report "C2P: stb is HIGH when no IDLE"
          severity failure;

      end if;

    end if;
 end process;
 end generate;


  X2X : if (g_slave_mode = g_master_mode) generate
  process (tb_clk_sys_i)
  begin
    if (rising_edge(tb_clk_sys_i) and (g_master_use_struct = TRUE)) then

      assert (tb_master_o.stb = tb_slave_i.stb)
        report "X2X: mismatch in stb"
        severity failure;

      assert (tb_slave_o.stall = tb_master_i.stall)
        report "X2X: mismatch in stall"
        severity failure;

      assert (tb_slave_o.ack = tb_master_i.ack)
        report "X2X: mismatch in ack"
        severity failure;

      assert (tb_slave_o.err = tb_master_i.err)
        report "X2X: mismatch in err"
        severity failure;

      assert (tb_slave_o.rty = tb_master_i.rty)
        report "X2X: mismatch in rty"
        severity failure;

    end if;
  end process;
  end generate X2X;

  general_assertions : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if (tb_rst_n_i = '1') then

          assert (tb_master_o.dat = tb_slave_i.dat)
            report "general: mismatch data between master_o and slave_i"
            severity failure;

          assert (tb_master_o.cyc = tb_slave_i.cyc)
            report "general: mismatch cyc"
            severity failure;

          assert (tb_master_o.sel = tb_slave_i.sel)
            report "general: mismatch sel"
            severity failure;

          assert (tb_master_o.we = tb_slave_i.we)
            report "general: mismatch we"
            severity failure;

          assert (tb_slave_o.dat = tb_master_i.dat)
            report "general: mismatch data between slave_o and master_i"
            severity failure;
      end if;
    end if;
  end process;


end tb;
