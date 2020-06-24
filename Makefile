
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
util = $(pwd)/../hccstar/rtl/Utility
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/twoclock_unfifo.v
TOPLEVEL = tb
MODULE = tb

include $(shell cocotb-config --makefiles)/Makefile.sim
