--------------------------------------------------------------------------------
-- CERN (BE-CEM-EDL)
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
--! unit name:   tb_xwb_crossbar
--!
--! author:      Konstantinos Blantos
--!
--! description: Testbench for an MxS Wishbone crossbar switch
--! All masters, slaves, and the crossbar itself must share the same WB clock.
--! All participants must support the same data bus width. 
--! 
--! If a master raises STB_O with an address not mapped by the crossbar,
--! ERR_I will be raised. If two masters address the same slave
--! simultaneously, the lowest numbered master is granted access.
--! 
--! The implementation of this crossbar locks a master to a slave so long as
--! CYC_O is held high. 
-- 
-- Synthesis/timing relevant facts:
--   (m)asters, (s)laves, masked (a)ddress bits
--   
--   Area required       = O(ms log(ma))
--   Arbitration depth   = O(log(msa))
--   Master->Slave depth = O(log(m))
--   Slave->Master depth = O(log(s))
-- 
--   If g_registered = false, arbitration depth is added to M->S and S->M.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2022
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_xwb_crossbar is
  generic (
    g_seed        : natural := 1992;
    g_num_masters : integer := 2;
    g_num_slaves  : integer := 1;
    g_registered  : boolean := false;
    g_address     : t_wishbone_address_array := (0=>x"00000000"); --(0 => x"11110000", 1 => x"1111110C");
    g_mask        : t_wishbone_address_array := (0=>x"00000000"); --(0 => x"1111110C", 1 => x"1111110C");
    g_verbose     : boolean := true);
end entity;

architecture tb of tb_xwb_crossbar is

  -- Constants
  constant C_CLK_SYS_PERIOD   : time := 10 ns;
  constant C_WISHBONE_SLAVE_I : t_wishbone_slave_in :=
    ('0', '0', x"00000000", x"0", '0', x"00000000");
  constant C_WISHBONE_MASTER_I: t_wishbone_master_in := 
    ('0', '0', '0', '0', x"00000000");

  -- Signals
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_slave_i   : t_wishbone_slave_in_array(g_num_masters-1 downto 0) := (others => C_WISHBONE_SLAVE_I);
  signal tb_slave_o   : t_wishbone_slave_out_array(g_num_masters-1 downto 0);
  signal tb_master_i  : t_wishbone_master_in_array(g_num_slaves-1 downto 0) := (others => C_WISHBONE_MASTER_I);
  signal tb_master_o  : t_wishbone_master_out_array(g_num_slaves-1 downto 0);
  signal tb_sdb_sel_o : std_logic_vector(g_num_masters-1 downto 0); 
  signal stop         : boolean;
  signal s_sdb_sel    : integer;

begin

  -- Unit Under Test
  UUT : entity work.xwb_crossbar
  generic map (
    g_num_masters => g_num_masters,
    g_num_slaves  => g_num_slaves,
    g_registered  => g_registered,
    g_address     => g_address,
    g_mask        => g_mask,
    g_verbose     => g_verbose)
  port map (
    clk_sys_i  => tb_clk_sys_i,
    rst_n_i    => tb_rst_n_i,
    master_i   => tb_master_i,
    master_o   => tb_master_o,
    slave_i    => tb_slave_i,
    slave_o    => tb_slave_o,
    sdb_sel_o  => tb_sdb_sel_o);

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
  tb_rst_n_i <= '0', '1' after 2*C_CLK_SYS_PERIOD;

  -- Stimulus
  stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING] with seed = " & to_string(g_seed);
    wait until tb_rst_n_i = '1';
    while NOW < 1 ms loop
      wait until rising_edge(tb_clk_sys_i);
      for i in 0 to g_num_slaves-1 loop
        tb_master_i(i).ack   <= data.randSlv(1)(1);
        tb_master_i(i).dat   <= data.randSlv(32);
        tb_master_i(i).err   <= data.randSlv(1)(1);
        tb_master_i(i).rty   <= data.randSlv(1)(1);
        tb_master_i(i).stall <= data.randSlv(1)(1);
      end loop;
      for j in 0 to g_num_masters-1 loop
        tb_slave_i(j).adr <= data.randSlv(c_wishbone_address_width);
        tb_slave_i(j).cyc <= data.randSlv(1)(1);
        tb_slave_i(j).dat <= data.randSlv(c_wishbone_data_width);
        tb_slave_i(j).sel <= data.randSlv(c_wishbone_address_width/8);
        tb_slave_i(j).stb <= data.randSlv(1)(1);
        tb_slave_i(j).we  <= data.randSlv(1)(1);
      end loop;
      ncycles    := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                        Assertions                                          --
  --------------------------------------------------------------------------------

  -- Convert sdb_sel_o into integer
  -- this is used like a pointer to point to the which slave 
  -- or master of the output side we are using everytime
  s_sdb_sel <= to_integer(unsigned(tb_sdb_sel_o)-1);

  
  -- Everytime that the sbd_sel_o is not zero
  -- and regarding of its value, these assertions are used
  -- to verify that the crossbar behaves properly

  -- comparison between input master and output slaves 
  compare_master_slave : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_sdb_sel_o /= "00" then
        assert (tb_master_i(0) = tb_slave_o(s_sdb_sel)) 
          report "Mismatch between master_i and slave_o" severity failure;
      else
        assert (tb_slave_o(0).stall = '1' and tb_slave_o(1).stall = '1')
          report "Not in stall when no-one is selected" severity failure;
      end if;
    end if;
  end process;

  -- comparison between input slaves and output master
  compare_slave_master : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_sdb_sel_o /= "00" then 
        assert (tb_master_o(0) = tb_slave_i(s_sdb_sel))
          report "Mismatch between slave_i and master_o" severity failure;
      end if;
    end if;
  end process;


end tb;

   
