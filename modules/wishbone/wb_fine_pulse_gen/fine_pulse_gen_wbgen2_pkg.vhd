---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for Generic Fine Pulse Generator Unit
---------------------------------------------------------------------------------------
-- File           : fine_pulse_gen_wbgen2_pkg.vhd
-- Author         : auto-generated by wbgen2 from fine_pulse_gen_wb.wb
-- Created        : Wed Jun 24 13:47:27 2020
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE fine_pulse_gen_wb.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

package fpg_wbgen2_pkg is
  
  
  -- Input registers (user design -> WB slave)
  
  type t_fpg_in_registers is record
    csr_ready_i                              : std_logic_vector(5 downto 0);
    csr_pll_locked_i                         : std_logic;
    odelay_calib_rdy_i                       : std_logic;
    odelay_calib_taps_i                      : std_logic_vector(8 downto 0);
  end record;
  
  constant c_fpg_in_registers_init_value: t_fpg_in_registers := (
    csr_ready_i => (others => '0'),
    csr_pll_locked_i => '0',
    odelay_calib_rdy_i => '0',
    odelay_calib_taps_i => (others => '0')
  );
  
  -- Output registers (WB slave -> user design)
  
  type t_fpg_out_registers is record
    csr_trig0_o                              : std_logic;
    csr_trig1_o                              : std_logic;
    csr_trig2_o                              : std_logic;
    csr_trig3_o                              : std_logic;
    csr_trig4_o                              : std_logic;
    csr_trig5_o                              : std_logic;
    csr_trig6_o                              : std_logic;
    csr_trig7_o                              : std_logic;
    csr_force0_o                             : std_logic;
    csr_force1_o                             : std_logic;
    csr_force2_o                             : std_logic;
    csr_force3_o                             : std_logic;
    csr_force4_o                             : std_logic;
    csr_force5_o                             : std_logic;
    csr_pll_rst_o                            : std_logic;
    csr_serdes_rst_o                         : std_logic;
    ocr0_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr0_fine_o                              : std_logic_vector(8 downto 0);
    ocr0_pol_o                               : std_logic;
    ocr0_mask_o                              : std_logic_vector(7 downto 0);
    ocr0_cont_o                              : std_logic;
    ocr0_trig_sel_o                          : std_logic;
    ocr1_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr1_fine_o                              : std_logic_vector(8 downto 0);
    ocr1_pol_o                               : std_logic;
    ocr1_mask_o                              : std_logic_vector(7 downto 0);
    ocr1_cont_o                              : std_logic;
    ocr1_trig_sel_o                          : std_logic;
    ocr2_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr2_fine_o                              : std_logic_vector(8 downto 0);
    ocr2_pol_o                               : std_logic;
    ocr2_mask_o                              : std_logic_vector(7 downto 0);
    ocr2_cont_o                              : std_logic;
    ocr2_trig_sel_o                          : std_logic;
    ocr3_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr3_fine_o                              : std_logic_vector(8 downto 0);
    ocr3_pol_o                               : std_logic;
    ocr3_mask_o                              : std_logic_vector(7 downto 0);
    ocr3_cont_o                              : std_logic;
    ocr3_trig_sel_o                          : std_logic;
    ocr4_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr4_fine_o                              : std_logic_vector(8 downto 0);
    ocr4_pol_o                               : std_logic;
    ocr4_mask_o                              : std_logic_vector(7 downto 0);
    ocr4_cont_o                              : std_logic;
    ocr4_trig_sel_o                          : std_logic;
    ocr5_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr5_fine_o                              : std_logic_vector(8 downto 0);
    ocr5_pol_o                               : std_logic;
    ocr5_mask_o                              : std_logic_vector(7 downto 0);
    ocr5_cont_o                              : std_logic;
    ocr5_trig_sel_o                          : std_logic;
    ocr6_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr6_fine_o                              : std_logic_vector(8 downto 0);
    ocr6_pol_o                               : std_logic;
    ocr6_mask_o                              : std_logic_vector(7 downto 0);
    ocr6_cont_o                              : std_logic;
    ocr6_trig_sel_o                          : std_logic;
    ocr7_pps_offs_o                          : std_logic_vector(3 downto 0);
    ocr7_fine_o                              : std_logic_vector(8 downto 0);
    ocr7_pol_o                               : std_logic;
    ocr7_mask_o                              : std_logic_vector(7 downto 0);
    ocr7_cont_o                              : std_logic;
    ocr7_trig_sel_o                          : std_logic;
    odelay_calib_rst_idelayctrl_o            : std_logic;
    odelay_calib_rst_odelay_o                : std_logic;
    odelay_calib_rst_oserdes_o               : std_logic;
    odelay_calib_value_o                     : std_logic_vector(8 downto 0);
    odelay_calib_value_update_o              : std_logic;
    odelay_calib_bitslip_o                   : std_logic_vector(1 downto 0);
    odelay_calib_en_vtc_o                    : std_logic;
    odelay_calib_cal_latch_o                 : std_logic;
  end record;
  
  constant c_fpg_out_registers_init_value: t_fpg_out_registers := (
    csr_trig0_o => '0',
    csr_trig1_o => '0',
    csr_trig2_o => '0',
    csr_trig3_o => '0',
    csr_trig4_o => '0',
    csr_trig5_o => '0',
    csr_trig6_o => '0',
    csr_trig7_o => '0',
    csr_force0_o => '0',
    csr_force1_o => '0',
    csr_force2_o => '0',
    csr_force3_o => '0',
    csr_force4_o => '0',
    csr_force5_o => '0',
    csr_pll_rst_o => '0',
    csr_serdes_rst_o => '0',
    ocr0_pps_offs_o => (others => '0'),
    ocr0_fine_o => (others => '0'),
    ocr0_pol_o => '0',
    ocr0_mask_o => (others => '0'),
    ocr0_cont_o => '0',
    ocr0_trig_sel_o => '0',
    ocr1_pps_offs_o => (others => '0'),
    ocr1_fine_o => (others => '0'),
    ocr1_pol_o => '0',
    ocr1_mask_o => (others => '0'),
    ocr1_cont_o => '0',
    ocr1_trig_sel_o => '0',
    ocr2_pps_offs_o => (others => '0'),
    ocr2_fine_o => (others => '0'),
    ocr2_pol_o => '0',
    ocr2_mask_o => (others => '0'),
    ocr2_cont_o => '0',
    ocr2_trig_sel_o => '0',
    ocr3_pps_offs_o => (others => '0'),
    ocr3_fine_o => (others => '0'),
    ocr3_pol_o => '0',
    ocr3_mask_o => (others => '0'),
    ocr3_cont_o => '0',
    ocr3_trig_sel_o => '0',
    ocr4_pps_offs_o => (others => '0'),
    ocr4_fine_o => (others => '0'),
    ocr4_pol_o => '0',
    ocr4_mask_o => (others => '0'),
    ocr4_cont_o => '0',
    ocr4_trig_sel_o => '0',
    ocr5_pps_offs_o => (others => '0'),
    ocr5_fine_o => (others => '0'),
    ocr5_pol_o => '0',
    ocr5_mask_o => (others => '0'),
    ocr5_cont_o => '0',
    ocr5_trig_sel_o => '0',
    ocr6_pps_offs_o => (others => '0'),
    ocr6_fine_o => (others => '0'),
    ocr6_pol_o => '0',
    ocr6_mask_o => (others => '0'),
    ocr6_cont_o => '0',
    ocr6_trig_sel_o => '0',
    ocr7_pps_offs_o => (others => '0'),
    ocr7_fine_o => (others => '0'),
    ocr7_pol_o => '0',
    ocr7_mask_o => (others => '0'),
    ocr7_cont_o => '0',
    ocr7_trig_sel_o => '0',
    odelay_calib_rst_idelayctrl_o => '0',
    odelay_calib_rst_odelay_o => '0',
    odelay_calib_rst_oserdes_o => '0',
    odelay_calib_value_o => (others => '0'),
    odelay_calib_value_update_o => '0',
    odelay_calib_bitslip_o => (others => '0'),
    odelay_calib_en_vtc_o => '0',
    odelay_calib_cal_latch_o => '0'
  );

function "or" (left, right: t_fpg_in_registers) return t_fpg_in_registers;
function f_x_to_zero (x:std_logic) return std_logic;
function f_x_to_zero (x:std_logic_vector) return std_logic_vector;

component fine_pulse_gen_wb is
  port (
    rst_n_i                                  : in     std_logic;
    clk_sys_i                                : in     std_logic;
    clk_ref_i                                : in     std_logic;
    clk_odelay_i                             : in     std_logic;
    clk_oserdes_i                            : in     std_logic;
    slave_i                                  : in     t_wishbone_slave_in;
    slave_o                                  : out    t_wishbone_slave_out;
    int_o                                    : out    std_logic;
    regs_i                                   : in     t_fpg_in_registers;
    regs_o                                   : out    t_fpg_out_registers
  );
end component;

end package;

package body fpg_wbgen2_pkg is
function f_x_to_zero (x:std_logic) return std_logic is
begin
  if x = '1' then
    return '1';
  else
    return '0';
  end if;
end function;

function f_x_to_zero (x:std_logic_vector) return std_logic_vector is
  variable tmp: std_logic_vector(x'length-1 downto 0);
begin
  for i in 0 to x'length-1 loop
    if(x(i) = 'X' or x(i) = 'U') then
      tmp(i):= '0';
    else
      tmp(i):=x(i);
    end if; 
  end loop; 
  return tmp;
end function;

function "or" (left, right: t_fpg_in_registers) return t_fpg_in_registers is
  variable tmp: t_fpg_in_registers;
begin
  tmp.csr_ready_i := f_x_to_zero(left.csr_ready_i) or f_x_to_zero(right.csr_ready_i);
  tmp.csr_pll_locked_i := f_x_to_zero(left.csr_pll_locked_i) or f_x_to_zero(right.csr_pll_locked_i);
  tmp.odelay_calib_rdy_i := f_x_to_zero(left.odelay_calib_rdy_i) or f_x_to_zero(right.odelay_calib_rdy_i);
  tmp.odelay_calib_taps_i := f_x_to_zero(left.odelay_calib_taps_i) or f_x_to_zero(right.odelay_calib_taps_i);
  return tmp;
end function;

end package body;
