
TOPLEVEL_LANG = verilog
pwd = $(shell pwd)
util = $(pwd)/../hccstar/rtl/Utility
VERILOG_SOURCES = \
  $(pwd)/tb.v \
  $(pwd)/strobed_reg_sync.v \
  $(util)/aFifo/aFifo.v \
  $(util)/aFifo/sync_r2w.v \
  $(util)/aFifo/sync_w2r.v \
  $(util)/aFifo/fifomem.v \
  $(util)/aFifo/rptr_empty.v \
  $(util)/aFifo/wptr_full.v
TOPLEVEL = tb
MODULE = tb

include $(shell cocotb-config --makefiles)/Makefile.sim
