--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_register
--
-- description: Testbench for a simple Wishbone register. Supports both standard 
-- (aka "classic") as well as pipelined mode.
--
-- IMPORTANT: Introducing this module can have unpredictable results in your
-- WB interface. Always check with a simulation that this module does not brake
-- your interfaces.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2014-2018
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

library work;
use work.wishbone_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity tb_xwb_register is
    generic (
        g_seed    : natural;
        g_WB_MODE : t_wishbone_interface_mode := PIPELINED);
end entity;

architecture tb of tb_xwb_register is

    constant C_CLK_PERIOD : time := 10 ns;

    signal tb_rst_n_i  : std_logic;
    signal tb_clk_i    : std_logic;
    signal tb_slave_i  : t_wishbone_slave_in;
    signal tb_slave_o  : t_wishbone_slave_out;
    signal tb_master_i : t_wishbone_master_in;
    signal tb_master_o : t_wishbone_master_out;

    signal stop          : boolean;
    signal s_rst_n       : std_logic := '0'; 
    signal s_stall_int   : std_logic;
    signal s_slave_stb_d : std_logic;
    signal s_slave_cyc_d : std_logic;
    signal s_slave       : t_wishbone_slave_in;
    signal s_s2m_reg     : t_wishbone_slave_in;
    signal s_master      : t_wishbone_master_in;
    signal s_slave_cl    : t_wishbone_slave_in;

    type t_fsm_classic is (S_IDLE, S_STB, S_ACK);
    signal s_state_classic   : t_fsm_classic;

    type t_fsm_pipelined is (S_PASS, S_STALL, S_FLUSH);
    signal s_state_pipelined : t_fsm_pipelined;

    shared variable sv_cover : covPType;
    
    --------------------------------------------------------------------------------
    -- Procedures used for fsm coverage
    --------------------------------------------------------------------------------

    -- states for classic mode
    procedure fsm_covadd_states_classic (
        name  : in string;
        prev  : in t_fsm_classic;
        curr  : in t_fsm_classic;
        covdb : inout covPType) is
    begin
        covdb.AddCross ( name,
                         GenBin(t_fsm_classic'pos(prev)),
                         GenBin(t_fsm_classic'pos(curr)));
        wait;
    end procedure;
    
    -- states for pipelined
    procedure fsm_covadd_states_pipelined (
        name  : in string;
        prev  : in t_fsm_pipelined;
        curr  : in t_fsm_pipelined;
        covdb : inout covPType) is
    begin
        covdb.AddCross ( name,
                         GenBin(t_fsm_pipelined'pos(prev)),
                         GenBin(t_fsm_pipelined'pos(curr)));
        wait;
    end procedure;
    
    -- illegal 
    procedure fsm_covadd_illegal (
        name  : in string;
        covdb : inout covPType ) is
    begin
        covdb.AddCross(ALL_ILLEGAL,ALL_ILLEGAL);
        wait;
    end procedure;

    -- bin collection for classic mode
    procedure fsm_covcollect_classic (
        signal reset : in std_logic;
        signal clk   : in std_logic;
        signal state : in t_fsm_classic;
               covdb   : inout covPType) is
        variable v_state : t_fsm_classic := t_fsm_classic'left;
    begin
        wait until reset='1';
        loop
            v_state := state;
            wait until rising_edge(clk);
            covdb.ICover((t_fsm_classic'pos(v_state), t_fsm_classic'pos(state)));
        end loop;
        wait;
    end procedure;

    -- bin collection for pipelined mode
    procedure fsm_covcollect_pipelined (
        signal reset : in std_logic;
        signal clk   : in std_logic;
        signal state : in t_fsm_pipelined;
               covdb   : inout covPType) is
        variable v_state : t_fsm_pipelined := t_fsm_pipelined'left;
    begin
        wait until reset='1';
        loop
            v_state := state;
            wait until rising_edge(clk);
            covdb.ICover((t_fsm_pipelined'pos(v_state), t_fsm_pipelined'pos(state)));
        end loop;
        wait;
    end procedure;

begin

    -- Unit Under Test
    UUT : entity work.xwb_register
    generic map (
        g_WB_MODE => g_WB_MODE)
    port map (
        rst_n_i  => tb_rst_n_i,
        clk_i    => tb_clk_i,
        slave_i  => tb_slave_i,
        slave_o  => tb_slave_o,
        master_i => tb_master_i,
        master_o => tb_master_o);

    -- Clock generation
	clk_proc : process
	begin
		while STOP = FALSE loop
			tb_clk_i <= '1';
			wait for C_CLK_PERIOD/2;
			tb_clk_i <= '0';
			wait for C_CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_proc;

    -- reset generation
    tb_rst_n_i <= '0', '1' after 2*C_CLK_PERIOD;

    -- Stimulus
    stim : process
        variable data    : RandomPType;
        variable ncycles : natural;
    begin
        data.InitSeed(g_seed);
        wait until tb_rst_n_i = '1';
        while (NOW < 2 ms) loop
            wait until rising_edge(tb_clk_i);
            -- Slave inputs
            tb_slave_i.cyc <= data.randSlv(1)(1);
            tb_slave_i.stb <= data.randSlv(1)(1) when s_state_classic = S_IDLE else '0';
            tb_slave_i.we  <= data.randSlv(1)(1);
            tb_slave_i.adr <= data.randSlv(32);
            tb_slave_i.sel <= data.randSlv(4);
            tb_slave_i.dat <= data.randSlv(32);
            -- Master inputs
            tb_master_i.ack   <= data.randSlv(1)(1);
            tb_master_i.err   <= data.randSlv(1)(1);
            tb_master_i.stall <= data.randSlv(1)(1);
            tb_master_i.rty   <= data.randSlv(1)(1);
            tb_master_i.dat   <= data.randSlv(32);
            ncycles := ncycles + 1;
        end loop;
        report "Number of simulation cycles = " & to_string(ncycles);
        stop <= TRUE;
        report "Test PASS!";
        wait;
    end process stim;

    s_rst_n <= tb_rst_n_i AND tb_slave_i.cyc;

    --------------------------------------------------------------------------------
    -- Coverage
    --------------------------------------------------------------------------------

    -- CLASSIC MODE
    g_classic_mode : if (g_WB_MODE = CLASSIC) generate
       
        p_s2m : process (tb_clk_i)
        begin
            if rising_edge(tb_clk_i) then
                if s_rst_n = '0' then
                    s_state_classic    <= s_IDLE;
                else
                    case s_state_classic is
                        when s_IDLE =>
                            if tb_slave_i.stb = '1' then
                                s_state_classic <= S_STB;
                            end if;
                        when s_STB =>
                            if tb_master_i.ack = '1' then
                                s_state_classic <= s_ACK;
                            end if;
                        when s_ACK =>
                                s_state_classic <= s_IDLE;
                    end case;
                end if;
            end if;
        end process p_s2m;

        -- all possible legal changes
        fsm_covadd_states_classic("S_IDLE -> S_STB ",S_IDLE,S_STB ,sv_cover);
        fsm_covadd_states_classic("S_STB  -> S_ACK ",S_STB, S_ACK ,sv_cover);
        fsm_covadd_states_classic("S_STB  -> S_IDLE",S_STB, S_IDLE,sv_cover);
        fsm_covadd_states_classic("S_ACK  -> S_IDLE",S_ACK, S_IDLE,sv_cover);
        -- when current and next state is the same
        fsm_covadd_states_classic("S_IDLE -> S_IDLE",S_IDLE,S_IDLE,sv_cover);
        fsm_covadd_states_classic("S_STB  -> S_STB " ,S_STB, S_STB ,sv_cover);
        -- illegal states
        fsm_covadd_illegal("ILLEGAL",sv_cover);
        -- collect the cov bins
        fsm_covcollect_classic(tb_rst_n_i, tb_clk_i, s_state_classic, sv_cover);
    
    end generate g_classic_mode;

    -- PIPELINED MODE
    g_pipelined_mode : if (g_WB_MODE = PIPELINED) generate
        
        stall_proc : process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                if (s_rst_n = '0') then
                    s_slave_stb_d <= '0';
                    s_slave_cyc_d <= '0';
                else
                    s_slave_stb_d <= tb_slave_i.stb;
                    s_slave_cyc_d <= tb_slave_i.cyc;
                end if;
            end if;
        end process stall_proc;

        s_stall_int <= s_slave_cyc_d AND s_slave_stb_d AND tb_master_i.stall;

        -- finite state machine
        fsm_pipelined_mode : process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                if (s_rst_n = '0') then
                    s_state_pipelined <= S_PASS;
                else
                    case s_state_pipelined is

                        when S_PASS =>
                            if (s_stall_int = '1') then
                                s_s2m_reg <= tb_slave_i;
                                s_state_pipelined <= S_STALL;
                            else
                                s_state_pipelined <= S_PASS;
                            end if;

                        when S_STALL =>
                            if (s_stall_int = '0') then
                                s_state_pipelined <= S_FLUSH;
                            else
                                s_state_pipelined <= S_STALL;
                            end if;

                        when S_FLUSH =>
                            if (s_stall_int = '0') then
                                s_state_pipelined <= S_PASS;
                            else
                                s_s2m_reg <= tb_slave_i;
                                s_state_pipelined <= S_STALL;
                            end if;
                    end case;
                end if;
            end if;
        end process;

        -- all possible legal changes
        fsm_covadd_states_pipelined("S_PASS  -> S_STALL",S_PASS, S_STALL,sv_cover);
        fsm_covadd_states_pipelined("S_STALL -> S_FLUSH",S_STALL,S_FLUSH,sv_cover);
        fsm_covadd_states_pipelined("S_STALL -> s_PASS ",S_STALL,S_PASS ,sv_cover);
        fsm_covadd_states_pipelined("S_FLUSH -> S_PASS ",S_FLUSH,S_PASS ,sv_cover);
        fsm_covadd_states_pipelined("S_FLUSH -> S_STALL",S_FLUSH,S_STALL,sv_cover);
        -- when current and next state is the same
        fsm_covadd_states_pipelined("S_PASS  -> S_PASS ",S_PASS, S_PASS ,sv_cover);
        fsm_covadd_states_pipelined("S_STALL -> S_STALL",S_STALL,S_STALL,sv_cover);
        -- illegal states
        fsm_covadd_illegal("ILLEGAL",sv_cover);
        -- collect the cov bins
        fsm_covcollect_pipelined(tb_rst_n_i, tb_clk_i, s_state_pipelined, sv_cover);
    
    end generate g_pipelined_mode;
    
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

    -- Checks the right value of wishbone mode
    assert (g_WB_MODE = CLASSIC OR g_WB_MODE = PIPELINED)
        report "Wrong wishbone mode"
        severity failure;

    -- Checks the behavior of output
    g_pipelined_check : if (g_WB_MODE = PIPELINED) generate

        process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                if (s_rst_n = '0') then
                    s_slave <= c_DUMMY_WB_MASTER_OUT;
                else
                    if (s_state_pipelined = S_PASS) then
                        if (s_stall_int = '0') then
                            s_slave <= tb_slave_i;
                        end if;
                    elsif (s_state_pipelined = S_STALL) then
                        s_slave <= s_s2m_reg;
                    elsif (s_state_pipelined = S_FLUSH) then
                        s_slave <= tb_slave_i;
                    end if;
                end if;
            end if;
        end process;

        process
        begin
            while (stop = FALSE) loop
                wait until (rising_edge(tb_clk_i));
                if (s_rst_n = '0') then
                    wait for C_CLK_PERIOD;
                    assert (tb_master_o = c_DUMMY_WB_MASTER_OUT)
                        report "PIPELINED: Wrong values for master output when reset"
                        severity error;
                else
                    if (s_state_pipelined = S_PASS) then
                        if (s_stall_int = '0') then
                           wait for C_CLK_PERIOD;
                            assert (tb_master_o = s_slave)
                                report "PIPELINED pass state: Mismatch master output and slave input"
                                severity error;
                        end if;
                    elsif (s_state_pipelined = S_STALL) then
                        if (s_stall_int = '0') then
                        wait for C_CLK_PERIOD;
                        assert (tb_master_o = s_s2m_reg)
                            report "PIPELINED stall state: Mismatch master output and slave input"
                            severity error;
                        end if;
                    elsif (s_state_pipelined = S_FLUSH) then
                        if (s_stall_int = '0') then
                            wait for C_CLK_PERIOD;
                            assert (tb_master_o = s_slave)
                                report "PIPELINED flush state: Mismatch master output and slave input"
                                severity error;
                        end if;
                    end if;
                end if;
            end loop;
            wait;
        end process;

    end generate g_pipelined_check;

    slave_o_master_i_check : process(tb_clk_i)
    begin
        if (rising_edge(tb_clk_i)) then
            if (tb_rst_n_i = '1') then
                s_master <= tb_master_i;
                assert(tb_slave_o = s_master)
                    report "Mismatch between slave output and master input"
                    severity error;
            end if;
        end if;
    end process;


    g_classic_check : if (g_WB_MODE = CLASSIC) generate
    
        process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                if (s_rst_n = '0') then
                    s_slave_cl <= c_DUMMY_WB_SLAVE_IN;
                else
                    s_slave_cl <= tb_slave_i;
                end if;
            end if;
        end process;
        
        process(tb_clk_i)
        begin
            if (rising_edge(tb_clk_i)) then
                if (s_rst_n = '1') then
                    if (s_state_classic = S_IDLE) then
                        assert (tb_master_o = s_slave_cl)
                            report "CLASSIC: Mismatch master output and slave input"
                            severity error;
                    end if;
                end if;
            end if;
        end process;
 
    end generate g_classic_check;



end tb;
