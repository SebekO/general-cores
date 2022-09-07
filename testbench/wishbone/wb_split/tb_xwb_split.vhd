-------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- tb_xwb_split
-- https://ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_split
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for a simple wishbone spliter (a crossbar with 
--              1 master and 2 slaves).
-- note: Slaves addresses are not remapped.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
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

use work.gencores_pkg.all;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_xwb_split                     --
--=============================================================================

entity tb_xwb_split is
  generic (
    g_seed : natural;
    g_MASK : std_logic_vector(31 downto 0):=(others=>'1'));
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_split is

  -- Constant
  constant C_CLK_SYS_PERIOD : time := 10 ns;
  constant c_IDLE_WB_MASTER_IN : t_wishbone_master_in :=
    (ack => '0', err => '0', rty => '0', stall => '0', dat => c_DUMMY_WB_DATA);

  -- types
  type t_state is (S_IDLE, S_CONN);

  -- Signals
  signal tb_clk_sys_i : std_logic;
  signal tb_rst_n_i   : std_logic;
  -- Slave I/O
  signal tb_slave_i   : t_wishbone_slave_in;
  signal tb_slave_o   : t_wishbone_slave_out;
  -- Master I/O
  signal tb_master_i  : t_wishbone_master_in_array(1 downto 0);
  signal tb_master_o  : t_wishbone_master_out_array(1 downto 0);

  signal stop         : boolean;
  signal s_master     : t_wishbone_master_out_array(1 downto 0);
  signal s_slave      : t_wishbone_slave_out;
  signal s_state      : t_state;
  signal s_slv        : natural;
  signal s_stall      : std_logic;

  -- Shared variables used for coverage
  shared variable sv_cover : covPType;

  --------------------------------------------------------------------------------
  -- Procedures used for fsm coverage
  --------------------------------------------------------------------------------

  -- legal states
  procedure fsm_covadd_states (
    name  : in string;
    prev  : in t_state;
    curr  : in t_state;
    covdb : inout covPType) is
  begin
     covdb.AddCross ( name,
                      GenBin(t_state'pos(prev)),
                      GenBin(t_state'pos(curr)));
     wait;
  end procedure;
  
  -- illegal states
  procedure fsm_covadd_illegal (
    name  : in string;
    covdb : inout covPType ) is
  begin
    covdb.AddCross(ALL_ILLEGAL,ALL_ILLEGAL);
    wait;
  end procedure;

  -- bin collection 
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
    wait;
  end procedure;


begin

  -- Unit Under Test
  UUT : entity work.xwb_split
  generic map (
    g_MASK => g_MASK)
  port map (
    clk_sys_i => tb_clk_sys_i,
    rst_n_i   => tb_rst_n_i,
    slave_i   => tb_slave_i,
    slave_o   => tb_slave_o,
    master_i  => tb_master_i,
    master_o  => tb_master_o);

  -- Clock generation
  clk_sys_proc : process
  begin
    while stop = false loop
      tb_clk_sys_i <= '1';
      wait for C_CLK_SYS_PERIOD/2;
      tb_clk_sys_i <= '0';
      wait for C_CLK_SYS_PERIOD/2;
    end loop;
    wait;
  end process;

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
    while (NOW < 4 ms) loop
      wait until rising_edge(tb_clk_sys_i);
      -- Input Slave input
      tb_slave_i.cyc   <= data.randSlv(1)(1);
      tb_slave_i.stb   <= data.randSlv(1)(1);
      tb_slave_i.we    <= data.randSlv(1)(1);
      tb_slave_i.sel   <= data.randSlv(4);
      tb_slave_i.dat   <= data.randSlv(32);
      tb_slave_i.adr   <= data.randSlv(32);
      -- Input Master 0, 1
      -- regarding the value of the g_MASK
      -- if it is all zero then master_o(0)
      -- otherwise it is master_o(1)
      tb_master_i(0).ack   <= data.randSlv(1)(1);
      tb_master_i(0).err   <= data.randSlv(1)(1);
      tb_master_i(0).rty   <= data.randSlv(1)(1);
      tb_master_i(0).stall <= data.randSlv(1)(1);
      tb_master_i(0).dat   <= data.randSlv(32);
      tb_master_i(1).ack   <= data.randSlv(1)(1);
      tb_master_i(1).err   <= data.randSlv(1)(1);
      tb_master_i(1).rty   <= data.randSlv(1)(1);
      tb_master_i(1).stall <= data.randSlv(1)(1);
      tb_master_i(1).dat   <= data.randSlv(32);
      ncycles := ncycles + 1;
    end loop;
    report "Number of simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS!";
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                              Coverage                                      --
  --------------------------------------------------------------------------------

  s_slv <= 0 when g_MASK = x"0000" else 1;

  -- FSM description
  fsm : process(tb_clk_sys_i)
  begin
    if rising_edge(tb_clk_sys_i) then
      if tb_rst_n_i = '0' then
        s_state <= S_IDLE;
      else
        case s_state is
          when S_IDLE =>
            if (tb_slave_i.cyc = '1' and tb_slave_i.stb = '1') then
              s_state <= S_CONN;
            end if;

          when S_CONN =>
            if (tb_master_i(s_slv).ack = '1' or tb_master_i(s_slv).err = '1') then
              s_state <= S_IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- all possible legal state changes
  fsm_covadd_states("S_IDLE -> S_CONN",S_IDLE,S_CONN,sv_cover);
  fsm_covadd_states("S_CONN -> S_IDLE",S_CONN,S_IDLE,sv_cover);
  -- when current and next state is the same
  fsm_covadd_states("S_IDLE -> S_IDLE",S_IDLE,S_IDLE,sv_cover);
  fsm_covadd_states("S_CONN -> S_CONN",S_CONN,S_CONN,sv_cover);
  -- illegal states
  fsm_covadd_illegal("ILLEGAL",sv_cover);
  -- collect the cov bins
  fsm_covcollect(tb_rst_n_i, tb_clk_sys_i, s_state, sv_cover);

  -- coverage report
  cov_report : process
  begin
      wait until stop;
      sv_cover.writebin;
      report "Test PASS!";
  end process;

  --------------------------------------------------------------------------------
  --                          Assertions                                        --
  --------------------------------------------------------------------------------

  -- As described in the RTL, we can have up to 2 output masters
  assert (s_slv = 0 or s_slv = 1)
    report "Wrong number of output masters" severity failure;


  -- Master behavior and assertions
  master_out_behavior : process
  begin
    while stop = false loop
      wait until rising_edge(tb_clk_sys_i);
      if tb_rst_n_i = '0' then
        s_master <= (0 | 1 => c_DUMMY_WB_MASTER_OUT);
      else
        if (s_state = S_IDLE) then
          s_master <= (0 | 1 => c_DUMMY_WB_MASTER_OUT);
          if (tb_slave_i.cyc = '1' and tb_slave_i.stb = '1') then
            s_stall <= '1';
            s_master(0) <= tb_slave_i when g_MASK=x"0000" else c_DUMMY_WB_MASTER_OUT;
            s_master(1) <= tb_slave_i when g_MASK/=x"0000" else c_DUMMY_WB_MASTER_OUT;
          end if;
        elsif (s_state = S_CONN) then
          s_master(s_slv).stb <= tb_master_i(s_slv).stall and s_stall;
          s_stall <= s_stall and tb_master_i(s_slv).stall;
        end if;
      end if;
    end loop;
    wait;
  end process;

  master_out_check : process
  begin
    while stop = false loop
      wait until rising_edge(tb_clk_sys_i);
      assert (s_master(s_slv) = tb_master_o(s_slv))
        report "Master: Mismatch" severity failure;
    end loop;
    wait;
  end process;


  -- Slave behavior and assertions  
  slave_out_behavior : process
  begin
    while stop = false loop
      wait until rising_edge(tb_clk_sys_i);
      if tb_rst_n_i = '0' then
        s_slave <= c_IDLE_WB_MASTER_IN;
      else
        if (s_state = S_IDLE) then
          s_slave <= c_IDLE_WB_MASTER_IN;
          if (tb_slave_i.cyc = '1' and tb_slave_i.stb = '1') then
            s_slave.stall <= '1';
          end if;
        elsif (s_state=S_CONN) then
          s_slave <= tb_master_i(0) when g_MASK=x"0000" else tb_master_i(1);
          s_slave.stall <= '1';
        end if;
      end if;
    end loop;
    wait;
  end process;

  slave_out_check : process
  begin
    while stop = false loop
      wait until rising_edge(tb_clk_sys_i);
      assert (s_slave = tb_slave_o)
        report "Slave: Mismatch" severity failure;
    end loop;
    wait;
  end process;



end tb;
