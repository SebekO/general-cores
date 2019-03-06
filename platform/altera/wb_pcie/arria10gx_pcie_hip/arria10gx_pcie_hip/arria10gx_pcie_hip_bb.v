
module arria10gx_pcie_hip (
	pld_clk,
	coreclkout_hip,
	refclk,
	npor,
	pin_perst,
	pld_core_ready,
	pld_clk_inuse,
	serdes_pll_locked,
	reset_status,
	testin_zero,
	test_in,
	simu_mode_pipe,
	derr_cor_ext_rcv,
	derr_cor_ext_rpl,
	derr_rpl,
	dlup,
	dlup_exit,
	ev128ns,
	ev1us,
	hotrst_exit,
	int_status,
	l2_exit,
	lane_act,
	ltssmstate,
	rx_par_err,
	tx_par_err,
	cfg_par_err,
	ko_cpl_spc_header,
	ko_cpl_spc_data,
	currentspeed,
	tx_st_sop,
	tx_st_eop,
	tx_st_err,
	tx_st_valid,
	tx_st_ready,
	tx_st_data,
	rx_st_sop,
	rx_st_eop,
	rx_st_err,
	rx_st_valid,
	rx_st_ready,
	rx_st_data,
	clr_st,
	rx_st_bar,
	rx_st_mask,
	tx_cred_data_fc,
	tx_cred_fc_hip_cons,
	tx_cred_fc_infinite,
	tx_cred_hdr_fc,
	tx_cred_fc_sel,
	sim_pipe_pclk_in,
	sim_pipe_rate,
	sim_ltssmstate,
	eidleinfersel0,
	eidleinfersel1,
	eidleinfersel2,
	eidleinfersel3,
	powerdown0,
	powerdown1,
	powerdown2,
	powerdown3,
	rxpolarity0,
	rxpolarity1,
	rxpolarity2,
	rxpolarity3,
	txcompl0,
	txcompl1,
	txcompl2,
	txcompl3,
	txdata0,
	txdata1,
	txdata2,
	txdata3,
	txdatak0,
	txdatak1,
	txdatak2,
	txdatak3,
	txdetectrx0,
	txdetectrx1,
	txdetectrx2,
	txdetectrx3,
	txelecidle0,
	txelecidle1,
	txelecidle2,
	txelecidle3,
	txdeemph0,
	txdeemph1,
	txdeemph2,
	txdeemph3,
	txmargin0,
	txmargin1,
	txmargin2,
	txmargin3,
	txswing0,
	txswing1,
	txswing2,
	txswing3,
	phystatus0,
	phystatus1,
	phystatus2,
	phystatus3,
	rxdata0,
	rxdata1,
	rxdata2,
	rxdata3,
	rxdatak0,
	rxdatak1,
	rxdatak2,
	rxdatak3,
	rxelecidle0,
	rxelecidle1,
	rxelecidle2,
	rxelecidle3,
	rxstatus0,
	rxstatus1,
	rxstatus2,
	rxstatus3,
	rxvalid0,
	rxvalid1,
	rxvalid2,
	rxvalid3,
	rxdataskip0,
	rxdataskip1,
	rxdataskip2,
	rxdataskip3,
	rxblkst0,
	rxblkst1,
	rxblkst2,
	rxblkst3,
	rxsynchd0,
	rxsynchd1,
	rxsynchd2,
	rxsynchd3,
	currentcoeff0,
	currentcoeff1,
	currentcoeff2,
	currentcoeff3,
	currentrxpreset0,
	currentrxpreset1,
	currentrxpreset2,
	currentrxpreset3,
	txsynchd0,
	txsynchd1,
	txsynchd2,
	txsynchd3,
	txblkst0,
	txblkst1,
	txblkst2,
	txblkst3,
	txdataskip0,
	txdataskip1,
	txdataskip2,
	txdataskip3,
	rate0,
	rate1,
	rate2,
	rate3,
	rx_in0,
	rx_in1,
	rx_in2,
	rx_in3,
	tx_out0,
	tx_out1,
	tx_out2,
	tx_out3,
	app_int_sts,
	app_int_ack,
	app_msi_num,
	app_msi_req,
	app_msi_tc,
	app_msi_ack,
	pm_auxpwr,
	pm_data,
	pme_to_cr,
	pm_event,
	pme_to_sr,
	hpg_ctrler,
	tl_cfg_add,
	tl_cfg_ctl,
	tl_cfg_sts,
	cpl_err,
	cpl_pending,
	skp_os);	

	input		pld_clk;
	output		coreclkout_hip;
	input		refclk;
	input		npor;
	input		pin_perst;
	input		pld_core_ready;
	output		pld_clk_inuse;
	output		serdes_pll_locked;
	output		reset_status;
	output		testin_zero;
	input	[31:0]	test_in;
	input		simu_mode_pipe;
	output		derr_cor_ext_rcv;
	output		derr_cor_ext_rpl;
	output		derr_rpl;
	output		dlup;
	output		dlup_exit;
	output		ev128ns;
	output		ev1us;
	output		hotrst_exit;
	output	[3:0]	int_status;
	output		l2_exit;
	output	[3:0]	lane_act;
	output	[4:0]	ltssmstate;
	output		rx_par_err;
	output	[1:0]	tx_par_err;
	output		cfg_par_err;
	output	[7:0]	ko_cpl_spc_header;
	output	[11:0]	ko_cpl_spc_data;
	output	[1:0]	currentspeed;
	input	[0:0]	tx_st_sop;
	input	[0:0]	tx_st_eop;
	input	[0:0]	tx_st_err;
	input	[0:0]	tx_st_valid;
	output		tx_st_ready;
	input	[63:0]	tx_st_data;
	output	[0:0]	rx_st_sop;
	output	[0:0]	rx_st_eop;
	output	[0:0]	rx_st_err;
	output	[0:0]	rx_st_valid;
	input		rx_st_ready;
	output	[63:0]	rx_st_data;
	output		clr_st;
	output	[7:0]	rx_st_bar;
	input		rx_st_mask;
	output	[11:0]	tx_cred_data_fc;
	output	[5:0]	tx_cred_fc_hip_cons;
	output	[5:0]	tx_cred_fc_infinite;
	output	[7:0]	tx_cred_hdr_fc;
	input	[1:0]	tx_cred_fc_sel;
	input		sim_pipe_pclk_in;
	output	[1:0]	sim_pipe_rate;
	output	[4:0]	sim_ltssmstate;
	output	[2:0]	eidleinfersel0;
	output	[2:0]	eidleinfersel1;
	output	[2:0]	eidleinfersel2;
	output	[2:0]	eidleinfersel3;
	output	[1:0]	powerdown0;
	output	[1:0]	powerdown1;
	output	[1:0]	powerdown2;
	output	[1:0]	powerdown3;
	output		rxpolarity0;
	output		rxpolarity1;
	output		rxpolarity2;
	output		rxpolarity3;
	output		txcompl0;
	output		txcompl1;
	output		txcompl2;
	output		txcompl3;
	output	[31:0]	txdata0;
	output	[31:0]	txdata1;
	output	[31:0]	txdata2;
	output	[31:0]	txdata3;
	output	[3:0]	txdatak0;
	output	[3:0]	txdatak1;
	output	[3:0]	txdatak2;
	output	[3:0]	txdatak3;
	output		txdetectrx0;
	output		txdetectrx1;
	output		txdetectrx2;
	output		txdetectrx3;
	output		txelecidle0;
	output		txelecidle1;
	output		txelecidle2;
	output		txelecidle3;
	output		txdeemph0;
	output		txdeemph1;
	output		txdeemph2;
	output		txdeemph3;
	output	[2:0]	txmargin0;
	output	[2:0]	txmargin1;
	output	[2:0]	txmargin2;
	output	[2:0]	txmargin3;
	output		txswing0;
	output		txswing1;
	output		txswing2;
	output		txswing3;
	input		phystatus0;
	input		phystatus1;
	input		phystatus2;
	input		phystatus3;
	input	[31:0]	rxdata0;
	input	[31:0]	rxdata1;
	input	[31:0]	rxdata2;
	input	[31:0]	rxdata3;
	input	[3:0]	rxdatak0;
	input	[3:0]	rxdatak1;
	input	[3:0]	rxdatak2;
	input	[3:0]	rxdatak3;
	input		rxelecidle0;
	input		rxelecidle1;
	input		rxelecidle2;
	input		rxelecidle3;
	input	[2:0]	rxstatus0;
	input	[2:0]	rxstatus1;
	input	[2:0]	rxstatus2;
	input	[2:0]	rxstatus3;
	input		rxvalid0;
	input		rxvalid1;
	input		rxvalid2;
	input		rxvalid3;
	input		rxdataskip0;
	input		rxdataskip1;
	input		rxdataskip2;
	input		rxdataskip3;
	input		rxblkst0;
	input		rxblkst1;
	input		rxblkst2;
	input		rxblkst3;
	input	[1:0]	rxsynchd0;
	input	[1:0]	rxsynchd1;
	input	[1:0]	rxsynchd2;
	input	[1:0]	rxsynchd3;
	output	[17:0]	currentcoeff0;
	output	[17:0]	currentcoeff1;
	output	[17:0]	currentcoeff2;
	output	[17:0]	currentcoeff3;
	output	[2:0]	currentrxpreset0;
	output	[2:0]	currentrxpreset1;
	output	[2:0]	currentrxpreset2;
	output	[2:0]	currentrxpreset3;
	output	[1:0]	txsynchd0;
	output	[1:0]	txsynchd1;
	output	[1:0]	txsynchd2;
	output	[1:0]	txsynchd3;
	output		txblkst0;
	output		txblkst1;
	output		txblkst2;
	output		txblkst3;
	output		txdataskip0;
	output		txdataskip1;
	output		txdataskip2;
	output		txdataskip3;
	output	[1:0]	rate0;
	output	[1:0]	rate1;
	output	[1:0]	rate2;
	output	[1:0]	rate3;
	input		rx_in0;
	input		rx_in1;
	input		rx_in2;
	input		rx_in3;
	output		tx_out0;
	output		tx_out1;
	output		tx_out2;
	output		tx_out3;
	input		app_int_sts;
	output		app_int_ack;
	input	[4:0]	app_msi_num;
	input		app_msi_req;
	input	[2:0]	app_msi_tc;
	output		app_msi_ack;
	input		pm_auxpwr;
	input	[9:0]	pm_data;
	input		pme_to_cr;
	input		pm_event;
	output		pme_to_sr;
	input	[4:0]	hpg_ctrler;
	output	[3:0]	tl_cfg_add;
	output	[31:0]	tl_cfg_ctl;
	output	[52:0]	tl_cfg_sts;
	input	[6:0]	cpl_err;
	input		cpl_pending;
	output		skp_os;
endmodule
