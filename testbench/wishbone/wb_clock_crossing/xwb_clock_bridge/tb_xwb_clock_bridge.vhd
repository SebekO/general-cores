--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_clock_bridge
--
-- description: Testbench for Cross clock-domain wishbone adapter
--
--------------------------------------------------------------------------------
-- Copyright CERN 2018
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

-- IMPORTANT: If you reset one clock domain, you must reset BOTH!
-- Release of the reset lines may be arbitrarily out-of-phase

--==============================================================================
--                            Libraries & Packages                            --
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.genram_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_xwb_clock_bridge              --
--=============================================================================

entity tb_xwb_clock_bridge is
  generic (
    g_seed                : natural;
    g_SLAVE_PORT_WB_MODE  : t_wishbone_interface_mode := PIPELINED;
    g_MASTER_PORT_WB_MODE : t_wishbone_interface_mode := PIPELINED;
    g_SIZE                : natural                   := 16);
end entity tb_xwb_clock_bridge;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_clock_bridge is

  -- Constants
  constant C_SLAVE_CLK_PERIOD  : time := 10 ns;
  constant C_MASTER_CLK_PERIOD : time := 5 ns;
  constant C_WISHBONE_SLAVE_IN : t_wishbone_slave_in 
            := ('0','0',(others=>'0'),(others=>'0'),'0',(others=>'0'));
  constant C_WISHBONE_SLAVE_OUT : t_wishbone_slave_out 
            := ('0','0','0','0',(others=>'0'));
  constant C_S2M_FIFO_WIDTH : natural := c_wishbone_data_width+c_wishbone_address_width+5;
  constant C_M2S_FIFO_WIDTH : natural := c_wishbone_data_width+3;

  -- Signals
  signal tb_slave_clk_i    : std_logic;
  signal tb_slave_rst_n_i  : std_logic;
  signal tb_slave_i        : t_wishbone_slave_in := C_WISHBONE_SLAVE_IN;
  signal tb_slave_o        : t_wishbone_slave_out:= C_WISHBONE_SLAVE_OUT;
  signal tb_master_clk_i   : std_logic;
  signal tb_master_rst_n_i : std_logic;
  signal tb_master_i       : t_wishbone_master_in := C_WISHBONE_SLAVE_OUT;
  signal tb_master_o       : t_wishbone_master_out:= C_WISHBONE_SLAVE_IN;

  signal stop              : boolean;
  signal s_mst_wren        : std_logic := '0';
  signal s_mst_rden        : std_logic := '0';
  signal s_mst_rden_d1     : std_logic := '0';
  signal s_slv_wren        : std_logic := '0';
  signal s_slv_rden        : std_logic := '0';
  signal s_slv_data_o      : std_logic_vector(c_wishbone_data_width-1 downto 0);
  signal s_pend_tr         : std_logic; --pending transaction
  signal s_pend_cnt        : unsigned(f_log2_size(g_SIZE)-1 downto 0);
  signal s_block_en        : std_logic := '0';

  -- Use of this array in order to store the input data of the
  -- slave and compare it to the output data, so as to check 
  -- that they are the same
  type t_slv_array is array (0 to g_size) of std_logic_vector(31 downto 0);
  signal s_slave_o : t_slv_array := (others=>(others=>'0'));

  signal s_slv_wr_ptr      : natural   :=  0;
  signal s_slv_rd_ptr      : natural   :=  0;
  signal s_slave_o_ack     : std_logic := '0';
  signal s_slave_o_err     : std_logic := '0';
  signal s_slave_o_rty     : std_logic := '0';
  signal s_slave_o_stall   : std_logic := '0';
  signal s_master_o_cyc    : std_logic := '0';

  -- used in FIFOs as input signals
  signal s_s2m_fifo_i      : std_logic_vector(C_S2M_FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal s_m2s_fifo_i      : std_logic_vector(C_M2S_FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal s_s2m_fifo_o      : std_logic_vector(C_S2M_FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal s_m2s_fifo_o      : std_logic_vector(C_M2S_FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal s_s2m_empty       : std_logic := '0';
  signal s_s2m_full        : std_logic := '0';
  signal s_m2s_empty       : std_logic := '0';
  signal s_wr_count_o      : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others=>'0');
  signal s_block_lim       : unsigned(f_log2_size(g_SIZE)-1 downto 0) := (others=>'0');

begin

  -- Unit Under Test
  UUT : entity work.xwb_clock_bridge
  generic map (
    g_SLAVE_PORT_WB_MODE  => g_SLAVE_PORT_WB_MODE,
    g_MASTER_PORT_WB_MODE => g_MASTER_PORT_WB_MODE,
    g_SIZE                => g_SIZE)
  port map (
    slave_clk_i    => tb_slave_clk_i,
    slave_rst_n_i  => tb_slave_rst_n_i,
    slave_i        => tb_slave_i,
    slave_o        => tb_slave_o,
    master_clk_i   => tb_master_clk_i,
    master_rst_n_i => tb_master_rst_n_i,
    master_i       => tb_master_i,
    master_o       => tb_master_o);

  -- Slave clock generation
  slave_clk_proc : process
  begin
    while stop = false loop
      tb_slave_clk_i <= '1';
      wait for C_SLAVE_CLK_PERIOD/2;
      tb_slave_clk_i <= '0';
      wait for C_SLAVE_CLK_PERIOD/2;
    end loop;
    wait;
  end process slave_clk_proc;

  -- Master clock generation
  master_clk_proc : process
  begin
    while stop = false loop
      tb_master_clk_i <= '1';
      wait for C_MASTER_CLK_PERIOD/2;
      tb_master_clk_i <= '0';
      wait for C_MASTER_CLK_PERIOD/2;
    end loop;
    wait;
  end process master_clk_proc;

  -- Slave reset generation
  tb_slave_rst_n_i  <= '0', '1' after 4*C_SLAVE_CLK_PERIOD;

  -- Master reset generation
  tb_master_rst_n_i <= '0', '1' after 4*C_MASTER_CLK_PERIOD;

  -- Stimulus for slave
  slave_stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Slave] with seed = " & to_string(g_seed);
    while NOW < 2 ms loop
      wait until rising_edge(tb_slave_clk_i) and tb_slave_rst_n_i = '1';
      tb_slave_i.cyc   <= data.randSlv(1)(1);
      tb_slave_i.stb   <= data.randSlv(1)(1);
      tb_slave_i.adr   <= data.randSlv(c_wishbone_address_width);
      tb_slave_i.sel   <= data.randSlv(c_wishbone_address_width/8);
      tb_slave_i.we    <= data.randSlv(1)(1);
      tb_slave_i.dat   <= data.randSlv(c_wishbone_data_width);
      ncycles          := ncycles + 1;
    end loop;
    report "Slave: Number of simulation cycles = " & to_string(ncycles);
    stop <= true;
    report "Test PASS";
    wait;
  end process slave_stim;

  -- Stimulus for master
  master_stim : process
    variable data    : RandomPType;
    variable ncycles : natural;
  begin
    data.InitSeed(g_seed);
    report "[STARTING Master] with seed = " & to_string(g_seed);
    while not stop loop
      wait until rising_edge(tb_master_clk_i) and tb_master_rst_n_i = '1';
      tb_master_i.ack   <= data.randSlv(1)(1);
      tb_master_i.err   <= data.randSlv(1)(1);
      tb_master_i.rty   <= data.randSlv(1)(1);
      tb_master_i.stall <= data.randSlv(1)(1);
      tb_master_i.dat   <= data.randSlv(c_wishbone_data_width);
      ncycles           := ncycles + 1;
    end loop;
    report "Master: Number of simulation cycles = " & to_string(ncycles);
    wait;
  end process master_stim;

  -- Write and read enable for master and slave
  s_mst_wren <= tb_master_o.cyc and (tb_master_i.ack or tb_master_i.err or tb_master_i.rty);
  s_slv_wren <= not s_s2m_full and tb_slave_i.cyc and tb_slave_i.stb; --OK
  s_mst_rden <= not s_m2s_empty; --OK
  s_slv_rden <= not (s_s2m_empty or s_block_en) and 
                not (s_pend_tr and tb_master_i.stall);

  -- Delayed by 1 clock master read enable
  p_mst_rden_delay : process(tb_slave_clk_i)
  begin
    if rising_edge(tb_slave_clk_i) then
      s_mst_rden_d1 <= s_mst_rden;
    end if;
  end process;

  -- In order to have the full/empty signals needed for the generation of write
  -- and read enable signals we use the same FIFOs as they are used in RTL code
  
  -- Input data for the s2m FIFO
  s_s2m_fifo_i(C_S2M_FIFO_WIDTH-1 downto (C_S2M_FIFO_WIDTH-c_wishbone_address_width-1)+1) <= tb_slave_i.adr;
  s_s2m_fifo_i(c_S2M_FIFO_WIDTH - c_WISHBONE_ADDRESS_WIDTH - 1 downto 5) <= tb_slave_i.dat;
  s_s2m_fifo_i(4 downto 1) <= tb_slave_i.sel;
  s_s2m_fifo_i(0) <= tb_slave_i.we;
  
  cmp_s2m_fifo : generic_async_fifo_dual_rst
    generic map (
      g_DATA_WIDTH => c_S2M_FIFO_WIDTH,
      g_SIZE       => g_SIZE)
    port map (
      rst_wr_n_i => tb_slave_rst_n_i,
      clk_wr_i   => tb_slave_clk_i,
      d_i        => s_s2m_fifo_i,
      we_i       => s_slv_wren,
      wr_full_o  => s_s2m_full,
      rst_rd_n_i => tb_master_rst_n_i,
      clk_rd_i   => tb_master_clk_i,
      q_o        => s_s2m_fifo_o,
      rd_i       => s_slv_rden,
      rd_empty_o => s_s2m_empty);

  -- Input data for the m2s FIFO
  s_m2s_fifo_i(C_M2S_FIFO_WIDTH-1 downto 3) <= tb_master_i.dat;
  s_m2s_fifo_i(2) <= tb_master_i.ack;
  s_m2s_fifo_i(1) <= tb_master_i.err;
  s_m2s_fifo_i(0) <= tb_master_i.rty;

  cmp_m2s_fifo : generic_async_fifo_dual_rst
    generic map (
      g_DATA_WIDTH    => c_M2S_FIFO_WIDTH,
      g_WITH_WR_FULL  => FALSE,
      g_WITH_WR_COUNT => TRUE,
      g_SIZE          => g_SIZE)
    port map (
      rst_wr_n_i => tb_master_rst_n_i,
      clk_wr_i   => tb_master_clk_i,
      d_i        => s_m2s_fifo_i,
      we_i       => s_mst_wren,
      wr_count_o => s_wr_count_o,
      rst_rd_n_i => tb_slave_rst_n_i,
      clk_rd_i   => tb_slave_clk_i,
      q_o        => s_m2s_fifo_o,
      rd_i       => s_mst_rden,
      rd_empty_o => s_m2s_empty);

    -- Pending transaction signal
    s_pend_tr <= '0' when s_pend_cnt = 0 else '1';

    -- Limit of block and block enable
    s_block_lim <= to_unsigned(g_SIZE-1,s_wr_count_o'length) - unsigned(s_wr_count_o); 
    s_block_en  <= '0' when s_pend_cnt < s_block_lim else '1';

    -- Counter of pending WB transactions
    p_wb_cnt_trans : process(tb_master_clk_i) 
    begin
      if rising_edge(tb_master_clk_i) then
        if tb_master_rst_n_i = '0' then
          s_pend_cnt <= (others=>'0');
        elsif s_slv_rden = '1' and s_mst_wren = '0' then
          s_pend_cnt <= s_pend_cnt + 1;
        elsif s_slv_rden = '0' and s_mst_wren = '1' then
          s_pend_cnt <= s_pend_cnt - 1;
        end if;
      end if;
    end process p_wb_cnt_trans;

    -- Store the input valid data into an array
    p_wr_store_data : process(tb_master_clk_i)
    begin
      if rising_edge(tb_master_clk_i) then
        if s_mst_wren then
          s_slave_o(s_slv_wr_ptr) <= tb_master_i.dat;
          s_slv_wr_ptr <= s_slv_wr_ptr + 1;
        if s_slv_wr_ptr = g_SIZE then
          s_slv_wr_ptr <= 0;
        end if;
      end if;
    end if;
  end process p_wr_store_data;

  -- read pointer for the slave_o array
  p_rd_pointer : process(tb_slave_clk_i) 
  begin
    if rising_edge(tb_slave_clk_i) then
      if s_mst_rden then
        s_slv_rd_ptr <= s_slv_rd_ptr + 1;
        if s_slv_rd_ptr = g_SIZE then
          s_slv_rd_ptr <= 0;
        end if;
      end if;
    end if;
  end process p_rd_pointer;

  s_slave_o_stall <= s_s2m_full;

  -- Assertion between master_i and slave_o
  process(tb_slave_clk_i)
  begin
    if rising_edge(tb_slave_clk_i) then
      if (s_mst_rden='1' and s_slv_rd_ptr>0) then
        
        assert (s_slave_o(s_slv_rd_ptr-1)(31 downto 0) = tb_slave_o.dat)
          report "Slave Out: Data Mismatch" severity failure;

        assert (s_slave_o_ack = tb_slave_o.ack)
          report "Slave Out: ACK mismatch" severity failure;

        assert (s_slave_o_err = tb_slave_o.err)
          report "Slave Out: ERR mismatch" severity failure;

        assert (s_slave_o_rty = tb_slave_o.rty)
          report "Slave Out: RTY mismatch" severity failure;

        assert (s_slave_o_stall = tb_slave_o.stall)
          report "Slave Out: STALL mismatch" severity failure;

      end if;
    end if;
  end process;

  -- Acknowledge with a one clock cycle wide pulse per entry in M2S FIFO
  -- (M2S FIFO is read whenever it is not empty). Data is made available one
  -- clock cycle after sdm_rd_en is asserted.
  s_slave_o_ack <= tb_slave_i.cyc and s_m2s_fifo_o(2) and s_mst_rden_d1; --ACK of tb_slave_o 
  s_slave_o_err <= tb_slave_i.cyc and s_m2s_fifo_o(1) and s_mst_rden_d1; --ERR of tb_slave_o
  s_slave_o_rty <= tb_slave_i.cyc and s_m2s_fifo_o(0) and s_mst_rden_d1; --RTY of tb_slave_o

  -- Output master cyc signal 
  s_master_o_cyc <= s_pend_tr;


  -- Assertion between slave_i and master_o
  process(tb_slave_clk_i)
  begin
    if rising_edge(tb_master_clk_i) then
      if (s_slv_rden='1') then
        
        assert (s_s2m_fifo_o(36 downto 5) = tb_master_o.dat) 
          report "Master Out: Data Mismatch" severity failure;

        assert (s_s2m_fifo_o(68 downto 37) = tb_master_o.adr)
          report "Master Out: Address mismatch" severity failure;

        assert (s_s2m_fifo_o(4 downto 1) = tb_master_o.sel)
          report "Master Out: ERR mismatch" severity failure;

        assert (s_s2m_fifo_o(0) = tb_master_o.we)
          report "Master Out: RTY mismatch" severity failure;

        assert (s_master_o_cyc = tb_master_o.cyc)
          report "Master Out: CYC mismatch" severity failure;

      end if;
    end if;
  end process;


end tb;
