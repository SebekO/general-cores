-------------------------------------------------------------------------------
-- Title      : Testbench for AXI4Lite-to-WB bridge wrapper
-- Project    : General Cores
-------------------------------------------------------------------------------
-- File       : tb_xwb_axi4lite_bridge.vhd
-- Author     : Konstantinos Blantos
-- Company    : CERN (BE-CEM-EDL)
-- Platform   : FPGA-generics
-- Standard   : VHDL '2008
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN
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
-------------------------------------------------------------------------------

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_pkg.all;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_xwb_axi4lite_bridge           --
--=============================================================================

entity tb_xwb_axi4lite_bridge is
    generic (
        g_seed : natural);
end entity;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_axi4lite_bridge is

    -- Constants
    constant C_CLK_SYS_PERIOD : time    := 10 ns;
    constant C_TIMEOUT        : natural := 256;

    -- Signals
    signal tb_clk_sys_i    : std_logic;
    signal tb_rst_n_i      : std_logic;
    signal tb_axi4_slave_i : t_axi4_lite_slave_in_32;
    signal tb_axi4_slave_o : t_axi4_lite_slave_out_32;
    signal tb_wb_master_o  : t_wishbone_master_out;
    signal tb_wb_master_i  : t_wishbone_master_in;

    signal stop     : boolean;
    signal s_cnt    : unsigned(10 downto 0);
    signal s_awaddr : std_logic_vector(31 downto 0) := (others=>'0');
    signal s_araddr : std_logic_vector(31 downto 0) := (others=>'0');
    signal s_wdata  : std_logic_vector(31 downto 0) := (others=>'0');
    signal s_wstrb  : std_logic_vector(3 downto 0)  := (others=>'X');
    signal s_rdata  : std_logic_vector(31 downto 0) := (others=>'0');
    
    type t_state is
        (IDLE, 
        ISSUE_WRITE, 
        ISSUE_READ, 
        COMPLETE_WRITE, 
        COMPLETE_READ, 
        WAIT_ACK_READ, 
        WAIT_ACK_WRITE, 
        RESPONSE_READ, 
        RESPONSE_WRITE);

    signal s_state           : t_state;
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
    UUT : entity work.xwb_axi4lite_bridge
    port map (
        clk_sys_i    => tb_clk_sys_i,
        rst_n_i      => tb_rst_n_i,
        axi4_slave_i => tb_axi4_slave_i,
        axi4_slave_o => tb_axi4_slave_o,
        wb_master_o  => tb_wb_master_o,
        wb_master_i  => tb_wb_master_i);

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

    -- reset generation
    tb_rst_n_i <= '0', '1' after 2*C_CLK_SYS_PERIOD;

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        report "[STARTING Slave] with seed = " & to_string(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clk_sys_i);
            -- Slave inputs
            tb_axi4_slave_i.ARVALID <= data.randSlv(1)(1);
            tb_axi4_slave_i.AWVALID <= data.randSlv(1)(1);
            tb_axi4_slave_i.BREADY  <= data.randSlv(1)(1);
            tb_axi4_slave_i.RREADY  <= data.randSlv(1)(1);
            tb_axi4_slave_i.WLAST   <= data.randSlv(1)(1);
            tb_axi4_slave_i.WVALID  <= data.randSlv(1)(1);
            tb_axi4_slave_i.ARADDR  <= data.randSlv(32);
            tb_axi4_slave_i.AWADDR  <= data.randSlv(32);
            tb_axi4_slave_i.WDATA   <= data.randSlv(32);
            tb_axi4_slave_i.WSTRB   <= data.randSlv(4);
            -- Master inputs
            tb_wb_master_i.ack   <= data.randSlv(1)(1);
            tb_wb_master_i.err   <= data.randSlv(1)(1);
            tb_wb_master_i.rty   <= data.randSlv(1)(1);
            tb_wb_master_i.stall <= data.randSlv(1)(1);
            tb_wb_master_i.dat   <= data.randSlv(32);
           ncycles := ncycles + 1;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    --------------------------------------------------------------------------------
    -- Coverage
    --------------------------------------------------------------------------------

    -- FSM
    fsm_proc : process(tb_clk_sys_i)
    begin
        if rising_edge(tb_clk_sys_i) then
            if tb_rst_n_i = '0' then
                s_state <= IDLE;
            else
                case s_state is
                    
                    when IDLE =>
                        if (tb_axi4_slave_i.AWVALID = '1') then
                            s_state <= ISSUE_WRITE;
                            s_awaddr<= tb_axi4_slave_i.AWADDR;
                        elsif (tb_axi4_slave_i.ARVALID = '1') then
                            s_state <= ISSUE_READ;
                            s_araddr<= tb_axi4_slave_i.ARADDR;
                        end if;

                    when ISSUE_WRITE =>
                        if (tb_axi4_slave_i.WVALID = '1') then
                            s_state <= COMPLETE_WRITE;
                            s_wstrb <= tb_axi4_slave_i.WSTRB;
                            s_wdata <= tb_axi4_slave_i.WDATA;
                        end if;

                    when ISSUE_READ =>
                        s_state <= COMPLETE_READ;

                    when COMPLETE_READ =>
                        if (tb_wb_master_i.stall = '0') then
                            if (tb_wb_master_i.ack = '1') then
                                s_state <= IDLE;
                                s_rdata <= tb_wb_master_i.dat;
                            else
                                s_state <= WAIT_ACK_READ;
                                s_cnt   <= (others=>'0');
                            end if;
                        end if;

                    when COMPLETE_WRITE =>
                        if (tb_wb_master_i.stall = '0') then
                            if (tb_wb_master_i.ack = '1') then
                                s_state <= RESPONSE_WRITE;
                            else
                                s_state <= WAIT_ACK_WRITE;
                                s_cnt   <= (others=>'0');
                            end if;
                        end if;

                    when WAIT_ACK_WRITE =>
                        if (tb_wb_master_i.ack = '1') then
                            s_state              <= RESPONSE_WRITE;
                        elsif s_cnt = C_TIMEOUT then
                            s_state <= RESPONSE_WRITE;
                        end if;
                        s_cnt <= s_cnt + 1;

                    when WAIT_ACK_READ =>
                        if (tb_wb_master_i.ack = '1') then
                            s_state <= RESPONSE_READ;
                            s_rdata <= tb_wb_master_i.dat;
                        elsif s_cnt = C_TIMEOUT then
                            s_state <= RESPONSE_READ;
                            s_rdata <= (others=>'X');
                        end if;
                        s_cnt <= s_cnt + 1;

                    when RESPONSE_WRITE =>
                        if (tb_axi4_slave_i.BREADY = '1') then
                            s_state <= IDLE;
                        end if;

                    when RESPONSE_READ =>
                        if (tb_axi4_slave_i.RREADY = '1') then
                            s_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- all possible legal changes
    fsm_covadd_states("IDLE          -> ISSUE_READ    ",IDLE          ,ISSUE_READ    ,sv_cover);
    fsm_covadd_states("IDLE          -> ISSUE_WRITE   ",IDLE          ,ISSUE_WRITE   ,sv_cover);
    fsm_covadd_states("ISSUE_WRITE   -> COMPLETE_WRITE",ISSUE_WRITE   ,COMPLETE_WRITE,sv_cover);
    fsm_covadd_states("ISSUE_READ    -> COMPLETE_READ ",ISSUE_READ    ,COMPLETE_READ ,sv_cover);
    fsm_covadd_states("COMPLETE_READ -> WAIT_ACK_READ ",COMPLETE_READ ,WAIT_ACK_READ ,sv_cover);
    fsm_covadd_states("COMPLETE_READ -> IDLE          ",COMPLETE_READ ,IDLE          ,sv_cover);
    fsm_covadd_states("COMPLETE_WRITE-> WAIT_ACK_WRITE",COMPLETE_WRITE,WAIT_ACK_WRITE,sv_cover);
    fsm_covadd_states("COMPLETE_WRITE-> RESPONSE_WRITE",COMPLETE_WRITE,RESPONSE_WRITE,sv_cover);
    fsm_covadd_states("WAIT_ACK_WRITE-> RESPONSE_WRITE",WAIT_ACK_WRITE,RESPONSE_WRITE,sv_cover);
    fsm_covadd_states("WAIT_ACK_READ -> RESPONSE_READ ",WAIT_ACK_READ ,RESPONSE_READ ,sv_cover);
    fsm_covadd_states("RESPONSE_READ -> IDLE          ",RESPONSE_READ ,IDLE          ,sv_cover);
    fsm_covadd_states("RESPONSE_WRITE-> IDLE          ",RESPONSE_WRITE,IDLE          ,sv_cover);
    -- when current and next state is the same
    fsm_covadd_states("IDLE           -> IDLE          ",IDLE          ,IDLE          ,sv_cover);
    fsm_covadd_states("ISSUE_WRITE    -> ISSUE_WRITE   ",ISSUE_WRITE   ,ISSUE_WRITE   ,sv_cover);
    fsm_covadd_states("COMPLETE_READ  -> COMPLETE_READ ",COMPLETE_READ ,COMPLETE_READ ,sv_cover);
    fsm_covadd_states("COMPLETE_WRITE -> COMPLETE_WRITE",COMPLETE_WRITE,COMPLETE_WRITE,sv_cover);
    fsm_covadd_states("WAIT_ACK_READ  -> WAIT_ACK_READ ",WAIT_ACK_READ ,WAIT_ACK_READ ,sv_cover);
    fsm_covadd_states("WAIT_ACK_WRITE -> WAIT_ACK_WRITE",WAIT_ACK_WRITE,WAIT_ACK_WRITE,sv_cover);
    fsm_covadd_states("RESPONSE_READ  -> RESPONSE_READ ",RESPONSE_READ ,RESPONSE_READ ,sv_cover);
    fsm_covadd_states("RESPONSE_WRITE -> RESPONSE_WRITE",RESPONSE_WRITE,RESPONSE_WRITE,sv_cover);
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
    -- Assertions
    --------------------------------------------------------------------------------

    -- Write
    process
    begin
        while not stop loop
            wait until rising_edge(tb_clk_sys_i) and tb_rst_n_i = '1';
            
            if (s_state = ISSUE_WRITE) then

                assert (tb_wb_master_o.adr = s_awaddr)
                    report "Wrong read address" severity failure;
                
                if (tb_axi4_slave_i.WVALID = '1') then
                    wait for 0.1 ns;
                    assert (tb_wb_master_o.sel = s_wstrb)
                        report "Wrong wb sel" severity failure;
                    assert (tb_wb_master_o.dat = s_wdata)
                        report "Wrong wb data" severity failure;
                end if;
            
            elsif (s_state = ISSUE_READ) then
                
                assert (tb_wb_master_o.adr = s_araddr)
                    report "Wrong write address" severity failure;
            
            elsif (s_state = COMPLETE_READ) then
                
                if (tb_wb_master_i.stall = '0') then
                    if (tb_wb_master_i.ack = '1') then
                        wait for 0.1 ns;
                        assert (tb_axi4_slave_o.RDATA = s_rdata)
                            report "Wrong read data" severity failure;
                        assert (tb_axi4_slave_o.RVALID = '1')
                            report "Wrong read valid" severity failure;
                        assert (tb_wb_master_o.cyc = '0')
                            report "Wrong cyc" severity failure;
                    end if;
                end if;

            elsif (s_state = WAIT_ACK_WRITE) then
                if (tb_wb_master_i.ack = '1') then
                    wait for 0.1 ns;
                    assert (tb_axi4_slave_o.BRESP = c_AXI4_RESP_OKAY)
                        report "Wrong BRESP" severity failure;
                end if;

            elsif (s_state = WAIT_ACK_READ) then
                if (tb_wb_master_i.ack = '1') then
                    wait for 0.1 ns;
                    assert (tb_axi4_slave_o.RDATA = s_rdata
                            AND tb_axi4_slave_o.RVALID = '1')
                        report "Wrong read data when wait for ack" severity failure;
                end if;

            elsif (s_state = RESPONSE_WRITE) then
                if (tb_axi4_slave_i.BREADY = '1') then
                    wait for 0.1 ns;
                    assert (tb_axi4_slave_o.BVALID = '0')
                        report "Wrong BVALID" severity failure;
                end if;

            elsif (s_state = RESPONSE_READ) then
                if (tb_axi4_slave_i.RREADY = '1') then
                    wait for 0.1 ns;
                    assert (tb_axi4_slave_o.RVALID = '0')
                        report "Wrong RVALID" severity failure;
                end if;
            
            end if;
        end loop;
        wait;
    end process;



end tb;
