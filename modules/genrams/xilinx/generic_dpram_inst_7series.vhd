--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   generic_dpram_inst_7series
--
-- description: True dual-port synchronous RAM for Xilinx FPGAs using Xilinx's
-- macros with:
-- - configurable address and data bus width
-- - byte-addressing mode (data bus width restricted to multiple of 8 bits)
--
--
--------------------------------------------------------------------------------
-- Copyright CERN 2017-2023
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

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;

library work;
use work.gencores_pkg.all;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity generic_dpram_inst_7series is
  generic (
    g_fpga_family              : string  := "kintex7";
    g_data_width               : natural := 32;
    g_size                     : natural := 16384;
    g_with_byte_enable         : boolean := false;
    g_addr_conflict_resolution : string  := "read_first";
    g_init_file                : string  := "";
    g_fail_if_file_not_found   : boolean := true;
    g_implementation_hint      : string  := "auto");
  port (
    rst_n_i: in std_logic;

    -- Port A
    clka_i : in  std_logic;
    bwea_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    wea_i  : in  std_logic;
    aa_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    da_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qa_o   : out std_logic_vector(g_data_width-1 downto 0);

    -- Port B
    clkb_i : in  std_logic;
    bweb_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    web_i  : in  std_logic;
    ab_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    db_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qb_o   : out std_logic_vector(g_data_width-1 downto 0));
end generic_dpram_inst_7series;

architecture syn of generic_dpram_inst_7series is
  constant c_num_bytes  : integer := (g_data_width+7)/8;
  constant c_ram_depth  : integer := 4096 / c_num_bytes;
  constant c_ram_count  : integer := (g_size + (c_ram_depth - 1))/c_ram_depth;

  type t_do is array(0 to c_ram_count-1) of std_logic_vector(g_data_width-1 downto 0);

  signal mux_doa : t_do;
  signal mux_dob : t_do;

  signal aa_tmp : std_logic_vector(f_log2_size(g_size)-1 downto 0);
  signal ab_tmp : std_logic_vector(f_log2_size(g_size)-1 downto 0);

  signal ena : std_logic_vector(c_ram_count-1 downto 0);
  signal enb : std_logic_vector(c_ram_count-1 downto 0);

  signal s_we_a  : std_logic_vector(c_num_bytes-1 downto 0);
  signal s_we_b  : std_logic_vector(c_num_bytes-1 downto 0);
  signal wea_rep : std_logic_vector(c_num_bytes-1 downto 0);
  signal web_rep : std_logic_vector(c_num_bytes-1 downto 0);

  signal rst : std_logic;
begin
  -----------------------------------------------------------------------------
  -- Check for unsupported features and/or misconfiguration
  -----------------------------------------------------------------------------
  gen_unknown_fpga : if (g_fpga_family /= "kintex7" and g_fpga_family /=
    "artix7") generate
    assert FALSE
      report "Xilinx FPGA family [" & g_fpga_family & "] is not supported"
      severity ERROR;
  end generate gen_unknown_fpga;

  gen_unsupported_conflict_res : if (g_addr_conflict_resolution /= "read_first"
    and g_addr_conflict_resolution /= "write_first") generate
    assert FALSE
      report "Address conflict resolution [" & g_addr_conflict_resolution & "] is not supported"
      severity ERROR;
  end generate gen_unsupported_conflict_res;

  rst <= not rst_n_i;

  -- combine byte-write enable with write signals
  gen_with_byte_enable: if (g_with_byte_enable = true) generate
    wea_rep <= (others => wea_i);
    web_rep <= (others => web_i);
    s_we_a <= bwea_i and wea_rep;
    s_we_b <= bweb_i and web_rep;
  end generate gen_with_byte_enable;
  gen_without_byte_enable: if (g_with_byte_enable = false) generate
    s_we_a <= (others => wea_i);
    s_we_b <= (others => web_i);
  end generate gen_without_byte_enable;

  qa_o <= mux_doa(f_check_bounds(to_integer(unsigned(aa_tmp(f_log2_size(g_size)-1 downto f_log2_size(c_ram_depth)))), 0, c_ram_count-1));
  qb_o <= mux_dob(f_check_bounds(to_integer(unsigned(ab_tmp(f_log2_size(g_size)-1 downto f_log2_size(c_ram_depth)))), 0, c_ram_count-1));

  delay_addr_a: process (clka_i)
    begin
      if rising_edge(clka_i) then
        aa_tmp <= aa_i;
      end if;
  end process;

  delay_addr_b: process (clkb_i)
    begin
      if rising_edge(clkb_i) then
        ab_tmp <= ab_i;
      end if;
  end process;

  gen_RAM: for I in 0 to c_ram_count-1 generate
  begin
    ena(I) <= '1' when f_check_bounds(to_integer(unsigned(aa_i(f_log2_size(g_size)-1 downto f_log2_size(c_ram_depth)))), 0, c_ram_count-1) = I else
              '0';
    enb(I) <= '1' when f_check_bounds(to_integer(unsigned(ab_i(f_log2_size(g_size)-1 downto f_log2_size(c_ram_depth)))), 0, c_ram_count-1) = I else
              '0';

    RAM : BRAM_TDP_MACRO
    generic map (
       BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
       DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
       DOA_REG => 0, -- Optional port A output register (0 or 1)
       DOB_REG => 0, -- Optional port B output register (0 or 1)
       INIT_A => X"000000000", -- Initial values on A output port
       INIT_B => X"000000000", -- Initial values on B output port
       INIT_FILE => "NONE",
       READ_WIDTH_A => g_data_width,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
       READ_WIDTH_B => g_data_width,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
       SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
       SRVAL_A => X"000000000",   -- Set/Reset value for A port output
       SRVAL_B => X"000000000",   -- Set/Reset value for B port output
       WRITE_MODE_A => to_upper(g_addr_conflict_resolution), -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
       WRITE_MODE_B => to_upper(g_addr_conflict_resolution), -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
       WRITE_WIDTH_A => g_data_width, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
       WRITE_WIDTH_B => g_data_width -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    )
    port map (
       DOA => mux_doa(I),         -- Output port-A data, width defined by READ_WIDTH_A parameter
       DOB => mux_dob(I),         -- Output port-B data, width defined by READ_WIDTH_B parameter
       ADDRA => aa_i(f_log2_size(c_ram_depth)-1 downto 0), -- Input port-A address, width defined by Port A depth
       ADDRB => ab_i(f_log2_size(c_ram_depth)-1 downto 0), -- Input port-B address, width defined by Port B depth
       CLKA => clka_i,            -- 1-bit input port-A clock
       CLKB => clkb_i,            -- 1-bit input port-B clock
       DIA => da_i,               -- Input port-A data, width defined by WRITE_WIDTH_A parameter
       DIB => db_i,               -- Input port-B data, width defined by WRITE_WIDTH_B parameter
       ENA => ena(I),             -- 1-bit input port-A enable
       ENB => enb(I),             -- 1-bit input port-B enable
       REGCEA => '1',             -- 1-bit input port-A output register enable
       REGCEB => '1',             -- 1-bit input port-B output register enable
       RSTA => rst,               -- 1-bit input port-A reset
       RSTB => rst,               -- 1-bit input port-B reset
       WEA => s_we_a,             -- Input port-A write enable, width defined by Port A depth
       WEB => s_we_b              -- Input port-B write enable, width defined by Port B depth
    );
  end generate;

end syn;
