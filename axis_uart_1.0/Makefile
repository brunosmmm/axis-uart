include $(shell cocotb-config --makefiles)/Makefile.sim

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = axis_uart_v1_0
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
VERILOG_SOURCES += $(wildcard hdl/*.v)

hdl/uart_axislave.v: misc/axislave.mmap
	axi_slave_builder $< -o $@


clean::
	@rm -rf dump.fst $(TOPLEVEL).fst
