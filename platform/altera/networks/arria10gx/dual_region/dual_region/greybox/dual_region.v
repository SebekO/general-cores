// Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, the Altera Quartus Prime License Agreement,
// the Altera MegaCore Function License Agreement, or other 
// applicable license agreement, including, without limitation, 
// that your use is for the sole purpose of programming logic 
// devices manufactured by Altera and sold by Altera or its 
// authorized distributors.  Please refer to the applicable 
// agreement for further details.

// VENDOR "Altera"
// PROGRAM "Quartus Prime"
// VERSION "Version 16.0.0 Build 211 04/27/2016 SJ Standard Edition"

// DATE "07/10/2018 17:11:57"

// 
// Device: Altera 10AX066H4F34I3SG Package FBGA1152
// 

// 
// This greybox netlist file is for third party Synthesis Tools
// for timing and resource estimation only.
// 


module dual_region (
	inclk,
	outclk)/* synthesis synthesis_greybox=0 */;
input 	inclk;
output 	outclk;

wire gnd;
wire vcc;
wire unknown;

assign gnd = 1'b0;
assign vcc = 1'b1;
// unknown value (1'bx) is not needed for this tool. Default to 1'b0
assign unknown = 1'b0;

wire \altclkctrl_0|dual_region_altclkctrl_160_7uwhdry_sub_component|wire_sd1_outclk ;
wire \inclk~input_o ;


dual_region_dual_region_altclkctrl_160_7uwhdry altclkctrl_0(
	.outclk(\altclkctrl_0|dual_region_altclkctrl_160_7uwhdry_sub_component|wire_sd1_outclk ),
	.inclk(\inclk~input_o ));

assign \inclk~input_o  = inclk;

assign outclk = \altclkctrl_0|dual_region_altclkctrl_160_7uwhdry_sub_component|wire_sd1_outclk ;

endmodule

module dual_region_dual_region_altclkctrl_160_7uwhdry (
	outclk,
	inclk)/* synthesis synthesis_greybox=0 */;
output 	outclk;
input 	inclk;

wire gnd;
wire vcc;
wire unknown;

assign gnd = 1'b0;
assign vcc = 1'b1;
// unknown value (1'bx) is not needed for this tool. Default to 1'b0
assign unknown = 1'b0;



dual_region_dual_region_altclkctrl_160_7uwhdry_sub dual_region_altclkctrl_160_7uwhdry_sub_component(
	.outclk(outclk),
	.inclk({gnd,gnd,gnd,inclk}));

endmodule

module dual_region_dual_region_altclkctrl_160_7uwhdry_sub (
	outclk,
	inclk)/* synthesis synthesis_greybox=0 */;
output 	outclk;
input 	[3:0] inclk;

wire gnd;
wire vcc;
wire unknown;

assign gnd = 1'b0;
assign vcc = 1'b1;
// unknown value (1'bx) is not needed for this tool. Default to 1'b0
assign unknown = 1'b0;



twentynm_clkena sd1(
	.inclk(inclk[0]),
	.ena(vcc),
	.outclk(outclk),
	.enaout());
defparam sd1.clock_type = "global clock";
defparam sd1.disable_mode = "low";
defparam sd1.ena_register_mode = "always enabled";
defparam sd1.ena_register_power_up = "high";
defparam sd1.test_syn = "high";

endmodule
