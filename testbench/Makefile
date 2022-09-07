# This Makefile can be called by the Continuous Integration (CI) tool to execute all
# testbenches added for CI

# AXI4 cores
TB_DIRS+=axi/axi4lite_wb_bridge
TB_DIRS+=axi/z7_axi_gpio_expander
TB_DIRS+=axi/axi4lite32_axi4full64_bridge
TB_DIRS+=axi/axi4lite_axi4full_bridge

# Common Cores
TB_DIRS+=common/gc_edge_detect
TB_DIRS+=common/gc_pulse_synchronizer2
TB_DIRS+=common/gc_reset_multi_aasd
TB_DIRS+=common/gc_sync
TB_DIRS+=common/gc_sync_ffs
TB_DIRS+=common/gc_sync_register
TB_DIRS+=common/gc_sync_word_rd
TB_DIRS+=common/gc_sync_word_wr
TB_DIRS+=common/gc_arbitrated_mux
TB_DIRS+=common/gc_delay_gen
TB_DIRS+=common/gc_delay_line
TB_DIRS+=common/gc_dyn_extend_pulse
TB_DIRS+=common/gc_glitch_filt
TB_DIRS+=common/gc_extend_pulse
TB_DIRS+=common/gc_dyn_extend_pulse
TB_DIRS+=common/gc_fsm_watchdog
TB_DIRS+=common/gc_async_counter_diff
TB_DIRS+=common/gc_async_signals_input_stage
TB_DIRS+=common/gc_multichannel_frequency_meter
TB_DIRS+=common/gc_negedge
TB_DIRS+=common/gc_posedge
TB_DIRS+=common/gc_reset
#TB_DIRS+=common/gc_prio_encoder
TB_DIRS+=common/gc_rr_arbiter
TB_DIRS+=common/gc_simple_spi_master
TB_DIRS+=common/gc_serial_dac
TB_DIRS+=common/gc_bicolor_led_ctrl
TB_DIRS+=common/gc_big_adder
TB_DIRS+=common/gc_comparator
TB_DIRS+=common/gc_moving_average
TB_DIRS+=common/gc_dual_pi_controller
TB_DIRS+=common/gc_word_packer
TB_DIRS+=common/gc_i2c_slave
TB_DIRS+=common/gc_ds182x_readout

# Genram cores
TB_DIRS+=genrams/common/inferred_async_fifo_dual_rst
TB_DIRS+=genrams/generic/generic_async_fifo_dual_rst
TB_DIRS+=genrams/xilinx/generic_dpram
TB_DIRS+=genrams/generic/generic_async_fifo
TB_DIRS+=genrams/generic/generic_sync_fifo
TB_DIRS+=genrams/altera/gc_shiftreg
TB_DIRS+=genrams/xilinx/generic_simple_dpram
TB_DIRS+=genrams/xilinx/generic_spram
TB_DIRS+=genrams/xilinx/generic_dpram_split
TB_DIRS+=genrams/xilinx/generic_dpram_sameclock
TB_DIRS+=genrams/xilinx/generic_dpram_dualclock
TB_DIRS+=genrams/xilinx/gc_shiftreg
TB_DIRS+=genrams/common/inferred_sync_fifo
TB_DIRS+=genrams/common/inferred_async_fifo

# Wishbone Cores
TB_DIRS+=wishbone/wb_axi4lite_bridge
TB_DIRS+=wishbone/wb_split
TB_DIRS+=wishbone/wb_dpram/xwb_dpram
TB_DIRS+=wishbone/wb_clock_crossing/xwb_clock_crossing
TB_DIRS+=wishbone/wb_clock_crossing/xwb_clock_bridge
TB_DIRS+=wishbone/wb_slave_adapter
TB_DIRS+=wishbone/wb_indirect
TB_DIRS+=wishbone/wb16_to_wb32
TB_DIRS+=wishbone/wb_metadata
TB_DIRS+=wishbone/wb_remapper
TB_DIRS+=wishbone/wb_async_bridge
TB_DIRS+=wishbone/wb_register/xwb_register
TB_DIRS+=wishbone/wb_register/xwb_register_link
TB_DIRS+=wishbone/wb_register/wb_skidpad
TB_DIRS+=wishbone/wb_crossbar/sdb_rom
TB_DIRS+=wishbone/wb_crossbar/xwb_crossbar

.PHONY: $(TB_DIRS)

all: $(TB_DIRS) summary

$(TB_DIRS):
	@echo "Compime OSVVM"
	cd "$@"; \
	/usr/local/lib/ghdl/vendors/compile-osvvm.sh --all 2>&1
	@echo $@
	@echo "Run HDLMAKE"
	cd "$@"; \
	hdlmake 2>&1
	@echo "Run make"
	$(MAKE) -C $@ $(TARGET)

	@echo "Run ghdl"
	cd "$@" ;\
	./run.sh
	echo "ghdl returned $$?"

summary: $(TB_DIRS)
	@echo "-------------------------------------------------------------------"
	@echo "Summary:"
	@for d in $(TB_DIRS); do \
		if [ -f $$d/transcript ]; then \
			echo "Warnings for $$d:"; \
			cat $$d/transcript | grep Warning; \
			if [ $$? -eq 1 ]; then echo "None"; fi ;\
			echo "Errors for $$d:"; \
			cat $$d/transcript | grep Error; \
			if [ $$? -eq 1 ]; then echo "None"; fi ;\
		else \
			echo "No transcript file for $$d"; \
		fi \
	done

clean:
	@for d in $(TB_DIRS); do \
		if [ -f $$d/Makefile ]; then \
			$(MAKE) -C $$d $@; \
			rm -f $$d/Makefile; \
		fi \
	done









