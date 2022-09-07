--------------------------------------------------------------------------------
-- CERN BE-CEM-EDL
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   tb_xwb_clock_crossing
--
-- author:      Konstantinos Blantos
--
-- description: Testbench for cross clock-domain wishbone adapter
--
--------------------------------------------------------------------------------
-- Copyright CERN 2012-2018
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
use work.genram_pkg.all;

-- OSVVM library
library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

--=============================================================================
--                   Entity declaration for tb_xwb_clock_crossing            --
--=============================================================================

entity tb_xwb_clock_crossing is
  generic (
    g_seed : natural;
    g_size : natural
  );
end entity tb_xwb_clock_crossing;

--==============================================================================
--                           Architecture declaration                         --
--==============================================================================

architecture tb of tb_xwb_clock_crossing is

  -- Constants
  constant C_SLAVE_CLK_PERIOD  : time := 10 ns;
  constant C_MASTER_CLK_PERIOD : time := 5 ns;
  constant C_POINTER_MAX       : natural := g_size;
  constant C_WISHBONE_SLAVE_IN : t_wishbone_slave_in 
            := ('0','0',(others=>'0'),(others=>'0'),'0',(others=>'0'));
  constant C_WISHBONE_SLAVE_OUT : t_wishbone_slave_out 
            := ('0','0','0','0',(others=>'0'));

  -- Signals
  signal tb_slave_clk_i    : std_logic;
  signal tb_slave_rst_n_i  : std_logic;
  signal tb_slave_i        : t_wishbone_slave_in := C_WISHBONE_SLAVE_IN;
  signal tb_slave_o        : t_wishbone_slave_out:= C_WISHBONE_SLAVE_OUT;
  signal tb_master_clk_i   : std_logic;
  signal tb_master_rst_n_i : std_logic;
  signal tb_master_i       : t_wishbone_master_in:= C_WISHBONE_SLAVE_OUT;
  signal tb_master_o       : t_wishbone_master_out:= C_WISHBONE_SLAVE_IN;
  signal tb_slave_ready_o  : std_logic := '0';
  signal tb_slave_stall_i  : std_logic := '0';
  signal tb_mr_empty       : std_logic := '0';
  signal tb_mw_full_o      : std_logic := '0';
  signal stop              : boolean   := false;
  
  -- Use of this array in order to store the input data and
  -- compare it to the output data, so as to check that they
  -- are the same
  type t_slv_array is array (0 to g_size) of std_logic_vector(35 downto 0);
  type t_mst_array is array (0 to g_size) of std_logic_vector(69 downto 0);
  signal s_slave_o : t_slv_array := (others=>(others=>'0')); -- contains the input slave
  signal s_master_o: t_mst_array := (others=>(others=>'0')); -- contains the input of master

  signal s_wr_ptr      : natural   :=  0;
  signal s_rd_ptr      : natural   :=  0;
  signal s_we_i        : std_logic := '0';
  signal s_rd_i        : std_logic := '0';
  signal s_slave_push  : std_logic := '0';
  signal s_slave_dat   : std_logic_vector(31 downto 0) := (others=>'0');
  signal s_slave_rty   : std_logic := '0';
  signal s_slave_err   : std_logic := '0';
  signal s_slave_ack   : std_logic := '0';
  signal s_full        : std_logic := '0';
  signal mpush         : unsigned(f_ceil_log2(g_size+1)-1 downto 0) := (others=>'0');
  signal mpop          : unsigned(f_ceil_log2(g_size+1)-1 downto 0) := (others=>'0');
  signal s_master_adr  : std_logic_vector(c_wishbone_address_width-1 downto 0) := (others=>'0');
  signal s_master_cyc  : std_logic := '0';
  signal s_master_dat  : std_logic_vector(c_wishbone_data_width-1 downto 0) := (others=>'0');
  signal s_master_sel  : std_logic_vector(c_wishbone_address_width/8-1 downto 0):= (others=>'0');
  signal s_master_stb  : std_logic := '0';
  signal s_mst_we_i    : std_logic := '0';
  signal s_mst_rd_i    : std_logic := '0';
  signal s_mst_wr_ptr  : natural   :=  0;
  signal s_mst_rd_ptr  : natural   :=  0;
  signal s_slave_cyc   : std_logic := '0';

--=============================================================================
--                            Architecture begin                             --
--=============================================================================

begin

  -- Unit Under Test
  UUT : entity work.xwb_clock_crossing
  generic map (
    g_size => g_size
  )
  port map (
    slave_clk_i    => tb_slave_clk_i,
    slave_rst_n_i  => tb_slave_rst_n_i,
    slave_i        => tb_slave_i,
    slave_o        => tb_slave_o,
    master_clk_i   => tb_master_clk_i,
    master_rst_n_i => tb_master_rst_n_i,
    master_i       => tb_master_i,
    master_o       => tb_master_o,
    mr_empty_o     => tb_mr_empty,
    slave_ready_o  => tb_slave_ready_o,
    slave_stall_i  => tb_slave_stall_i,
    mw_full_o      => tb_mw_full_o
    );

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

  -- These two resets should be reseted simultaneously.
  -- Release of the reset may be arbitrarily out-of-phase

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
    while NOW < 0.1 ms loop
      wait until rising_edge(tb_slave_clk_i) and tb_slave_rst_n_i = '1';
      tb_slave_i.cyc   <= data.randSlv(1)(1);
      tb_slave_i.stb   <= data.randSlv(1)(1);
      tb_slave_i.adr   <= data.randSlv(c_wishbone_address_width);
      tb_slave_i.sel   <= data.randSlv(c_wishbone_address_width/8);
      tb_slave_i.we    <= data.randSlv(1)(1);
      tb_slave_i.dat   <= data.randSlv(c_wishbone_data_width);
      tb_slave_stall_i <= data.randSlv(1)(1);
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

--=============================================================================
--                              Assertions                                   --
--=============================================================================

  -----------------------------------------------------------------------------
  --                            SLAVE SIDE                                   --
  -----------------------------------------------------------------------------

  s_we_i <= (tb_master_i.ack or tb_master_i.err or tb_master_i.rty);
  s_rd_i <= '1' when tb_slave_ready_o and not tb_slave_stall_i else '0';

  -- write pointer used in the array 
  -- which stored the input data
  -- store the input data from master to the array
  wr_ptr_storage_data : process(tb_master_clk_i)
  begin
    if rising_edge(tb_master_clk_i) then
      if s_we_i = '1' then
        s_slave_o(s_wr_ptr) <= tb_master_i.ack & tb_master_i.err & tb_master_i.rty & tb_master_i.stall & tb_master_i.dat;
        s_wr_ptr <= s_wr_ptr + 1;
        if s_wr_ptr = C_POINTER_MAX then
          s_wr_ptr <= 0;
        end if;
      end if;
    end if;
  end process wr_ptr_storage_data;


  -- read pointer used for comparison
  -- compare the data stored in array with the slave output data
  rd_ptr_rd_data : process(tb_slave_clk_i)
  begin
    if rising_edge(tb_slave_clk_i) then
      if s_rd_i = '1' then
        s_rd_ptr    <= s_rd_ptr + 1;
        if s_rd_ptr = C_POINTER_MAX then
          s_rd_ptr <= 0;
        end if;
      end if;
    end if;
  end process;

  s_slave_dat <= s_slave_o(s_rd_ptr)(31 downto 0) when s_rd_i = '1';
  
  -- ERR, RTY, ACK signals behavior of the output slave
  s_slave_rty   <= s_slave_o(s_rd_ptr)(33) and s_slave_push;
  s_slave_err   <= s_slave_o(s_rd_ptr)(34) and s_slave_push;
  s_slave_ack   <= s_slave_o(s_rd_ptr)(35) and s_slave_push;

  -- in order to calculate the output slave's stall signal
  -- there is a need to know when the fifo of the master's
  -- side is full. For that reason, we use the mpush, mpop
  -- counters and when they are equal, fifo is full
  cnt_push_pop : process(tb_slave_clk_i)
  begin
    if tb_slave_rst_n_i = '0' then
      mpush <= (others=>'0');
      mpop  <= to_unsigned(g_size,mpop'length); 
    elsif rising_edge(tb_slave_clk_i) then
      if (not s_full and tb_slave_i.cyc and tb_slave_i.stb) = '1' then
        mpush <= mpush + 1;
      end if;
      if s_slave_push then
        mpop <= mpop + 1;
      end if;
    end if;
  end process;

  -- drive slave port
  drv_slv_port : process(tb_slave_clk_i) 
  begin
    if rising_edge(tb_slave_clk_i) then
      if tb_slave_rst_n_i = '0' then
        s_slave_push <= '0';
        s_slave_cyc  <= '0';
      else
        s_slave_push <= s_rd_i;
        s_slave_cyc  <= tb_slave_i.cyc;
      end if;
    end if;
  end process;

  -- Full signal
  s_full <= '1' when mpush=mpop else '0';

  -- Checking the slave output
  compare_slv_data_with_tmp_data : process
  begin
    while not stop loop
      wait until rising_edge(tb_slave_clk_i);

      assert (s_full = tb_slave_o.stall)
        report "Slave out: STALL mismatch" severity failure;
      
      if s_rd_i = '1' then

        assert (s_slave_dat = tb_slave_o.dat) 
          report "Slave out: Data mismatch" severity failure;

        assert (s_slave_rty = tb_slave_o.rty)
          report "Slave out: RTY mismatch" severity failure;
 
        assert (s_slave_err = tb_slave_o.err)
          report "Slave out: ERR mismatch" severity failure;
 
        assert (s_slave_ack = tb_slave_o.ack)
          report "Slave out: ACK mismatch" severity failure;
 
      end if;
    end loop;
    wait;
  end process;

  --------------------------------------------------------------------------------
  --                                MASTER SIDE                                 --
  --------------------------------------------------------------------------------

  -- Write and Read enable of master side
  s_mst_we_i <= (not s_full and tb_slave_i.cyc and tb_slave_i.stb and not tb_mw_full_o) 
               or (not tb_slave_i.cyc and s_slave_cyc and not tb_mw_full_o);
  
  s_mst_rd_i <= not tb_mr_empty and (not tb_master_o.CYC or not s_master_stb or not tb_master_i.stall);
  


  drv_master_port : process(tb_master_clk_i)
  begin
    if rising_edge(tb_master_clk_i) then
      if tb_master_rst_n_i = '0' then
        s_master_stb <= '0';
      else
        s_master_stb <= s_mst_rd_i or (tb_master_o.cyc and s_master_stb and tb_master_i.stall);
      end if;
    end if;
  end process;


  -- write pointer used to point where to write
  -- the data in the array
  mst_wr_ptr_store_data : process(tb_slave_clk_i)
  begin
    if rising_edge(tb_slave_clk_i) then
      if s_mst_we_i = '1' then
        s_master_o(s_mst_wr_ptr) <= tb_slave_i.sel & tb_slave_i.dat & tb_slave_i.adr & tb_slave_i.we & tb_slave_i.cyc;
        s_mst_wr_ptr <= s_mst_wr_ptr + 1;
        if s_mst_wr_ptr = C_POINTER_MAX then
          s_mst_wr_ptr <= 0;
        end if;
      end if;
    end if;
  end process mst_wr_ptr_store_data;

  -- Read pointer for master. Used to specify the position 
  -- in the array, where the valid data is stored
  master_rd_pointer : process(tb_master_clk_i)
  begin
    if rising_edge(tb_master_clk_i) then
      if s_mst_rd_i = '1' then
        s_mst_rd_ptr <= s_mst_rd_ptr + 1;
        if s_mst_rd_ptr = C_POINTER_MAX then
          s_mst_rd_ptr <= 0;
        end if;
      end if;
    end if;
  end process;
  
  -- Assign to the Data, Sel, Address the right values
  -- from the array which has the incoming slave
  s_master_dat <= s_master_o(s_mst_rd_ptr)(65 downto 34) when s_mst_rd_i = '1';
  s_master_adr <= s_master_o(s_mst_rd_ptr)(33 downto 2)  when s_mst_rd_i = '1';
  s_master_sel <= s_master_o(s_mst_rd_ptr)(69 downto 66) when s_mst_rd_i = '1';


  -- Comparison between the TB signals and the
  -- RTL signals coming from the core
  compare_mst_data_with_tmp_data : process
  begin
    while not stop loop
      wait until rising_edge(tb_master_clk_i);

      if s_mst_rd_i = '1' then

        assert (s_master_dat = tb_master_o.dat) 
          report "Master out: Data mismatch" severity failure;

        assert (s_master_adr = tb_master_o.adr)
          report "Master out: Address mismatch" severity failure;

      end if;
    end loop;
    wait;
  end process;

end architecture tb;
