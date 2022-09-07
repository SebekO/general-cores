--------------------------------------------------------------------------------
-- CERN (BE-CEM-EDL)
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_sdb_rom
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for SDB ROM for WB crossbar
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

--=================================================================================================
--                                      Libraries & Packages
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=================================================================================================
--                           Entity declaration for tb_sdb_rom
--=================================================================================================


entity tb_sdb_rom is
  generic (
    g_seed     : natural;
    g_layout   : t_sdb_record_array := (0=>(others=>'0'));
    g_masters  : natural;
    g_bus_end  : unsigned(63 downto 0) := (others=>'1');
    g_wb_mode  : t_wishbone_interface_mode := CLASSIC;
    g_sdb_name : string                    := "WB4-Crossbar-GSI   ");
end entity;

--=================================================================================================
--                                    Architecture declaration
--=================================================================================================

architecture tb of tb_sdb_rom is

  -- Alias
  alias c_layout : t_sdb_record_array(g_layout'length downto 1) is g_layout;
  
  -- Constants
  constant C_CLK_SYS_PERIOD : time := 10 ns;
  constant C_WB_SLAVE_IN : t_wishbone_slave_in := 
      ('0', '0', (others=>'0'), (others=>'0'), '0', (others=>'0'));

  type t_rom_memory is array (0 to 31) of std_logic_vector(31 downto 0);

  -- copied from RTL core
  -- The ROM must describe all slaves, the crossbar itself and the optional information records
  constant c_used_entries   : natural := c_layout'high + 1;
  constant c_rom_entries    : natural := 2**f_ceil_log2(c_used_entries); -- next power of 2
  constant c_sdb_words      : natural := c_sdb_device_length / c_wishbone_data_width;
  constant c_rom_words      : natural := c_rom_entries * c_sdb_words;
  constant c_rom_depth      : natural := f_ceil_log2(c_rom_words);
  constant c_rom_lowbits    : natural := f_ceil_log2(c_wishbone_data_width / 8);
  constant c_sdb_name       : string  := f_string_fix_len(g_sdb_name , 19, ' ', false);


  -- Signals
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  signal tb_master_i  : std_logic_vector(g_masters-1 downto 0);
  signal tb_slave_i   : t_wishbone_slave_in := C_WB_SLAVE_IN;
  signal tb_slave_o   : t_wishbone_slave_out;
  signal stop         : boolean;
  signal s_ack        : std_logic := '0';

  signal s_addr       : unsigned(c_rom_depth-1 downto 0);
  signal s_data       : std_logic_vector(c_wishbone_data_width-1 downto 0); 
  signal s_rom        : t_rom_memory := 
    (0  => x"5344422D",
     1  => x"00020100",
     2  => x"00000000",
     3  => x"00000000",
     4  => x"FFFFFFFF",
     5  => x"FFFFFFFF",
     6  => x"00000000",
     7  => x"00000651",
     8  => x"E6A542C9",
     9  => x"00000003",
     10 => x"20120511",
     11 => x"5742342D",
     12 => x"43726F73",
     13 => x"73626172",
     14 => x"2D475349",
     15 => x"20202000",
     16 => x"00000000",
     17 => x"00000000",
     18 => x"00000000",
     19 => x"00000000",
     20 => x"00000000",
     21 => x"00000000",
     22 => x"00000000",
     23 => x"00000000",
     24 => x"00000000",
     25 => x"00000000",
     26 => x"00000000",
     27 => x"00000000",
     28 => x"00000000",
     29 => x"00000000",
     30 => x"00000000",
     31 => x"00000000");

begin

  -- Unit Under Test
  UUT : entity work.sdb_rom
  generic map (
    g_layout   => g_layout,
    g_masters  => g_masters,
    g_bus_end  => g_bus_end,
    g_wb_mode  => g_wb_mode,
    g_sdb_name => g_sdb_name)
  port map (
    clk_sys_i  => tb_clk_sys_i,
    rst_n_i    => tb_rst_n_i,
    master_i   => tb_master_i,
    slave_i    => tb_slave_i,
    slave_o    => tb_slave_o);

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
    while NOW < 2 ms loop
      wait until rising_edge(tb_clk_sys_i);
      tb_master_i    <= data.randSlv(g_masters);
      -- Slave signals
      tb_slave_i.cyc <= data.randSlv(1)(1);
      tb_slave_i.stb <= data.randSlv(1)(1);
      tb_slave_i.we  <= data.randSlv(1)(1);
      tb_slave_i.sel <= data.randSlv(4);
      tb_slave_i.adr <= data.randSlv(32);
      tb_slave_i.dat <= data.randSlv(32);
      ncycles        := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS!";
    wait;
  end process stim;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  s_addr <= unsigned(tb_slave_i.adr(c_rom_depth+c_rom_lowbits-1 downto c_rom_lowbits));

  -- the rom that simulates the one that RTL generates with these
  -- specific generic values



  -- check that the output signals of the slave 
  -- behaves like the specification
  
  -- ack signal is the cyc and stb of the slave_i
  check_ack : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '1' then
        s_ack <= tb_slave_i.cyc and tb_slave_i.stb;
        if s_ack then 
          assert (tb_slave_o.ack = s_ack)
            report "ACK mismatch in output slave" severity failure;
        end if;
      end if;
    end if;
  end process;

  -- Err, Rty and stall should be zero 
  err_rty_stall_check : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '1' then
        assert (tb_slave_o.err = '0' and tb_slave_o.rty = '0' and tb_slave_o.stall = '0')
          report "ERR of slave_o should be zero" severity failure;
      end if;
    end if;
  end process;

  -- store the output data from testbench
  -- Output data should take values only from ROM (for this testcase)
  check_data : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      s_data <= s_rom(to_integer(s_addr));
      assert (tb_slave_o.dat = s_data)
        report "Output data of the slave should have value from ROM"
        severity error;
    end if;
  end process;

end tb;

   
