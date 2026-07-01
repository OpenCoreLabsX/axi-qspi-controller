VERILATOR_BIN ?= C:/msys64/usr/bin/perl C:/msys64/ucrt64/bin/verilator
VERILATOR_FLAGS ?= --language 1800-2017
VLOG_BIN ?= vlog
VSIM_BIN ?= vsim
VLIB_BIN ?= vlib
VMAP_BIN ?= vmap
UVM_HOME ?= C:/intelFPGA/18.1/modelsim_ase/verilog_src/uvm-1.2
UVM_TEST ?= axi_qspi_all_test

FILELIST ?= filelist.f
UVM_FILELIST ?= filelist_uvm.f
TOP_MODULE ?= axi_qspi_wrapper

.PHONY: all lint uvm_compile uvm_run clean

all: lint

lint:
	$(VERILATOR_BIN) $(VERILATOR_FLAGS) --lint-only -f $(FILELIST) --top-module $(TOP_MODULE)

uvm_compile:
	$(VLIB_BIN) work
	$(VMAP_BIN) work work
	$(VLOG_BIN) -sv +define+UVM_NO_DPI +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv -f $(UVM_FILELIST)

uvm_run:
	$(VSIM_BIN) -c -suppress 19 axi_qspi_tb_top +UVM_TESTNAME=$(UVM_TEST) +UVM_NO_RELNOTES -do "run -all; quit -f"

clean:
	rm -rf obj_dir
	rm -rf work transcript vsim.wlf modelsim.ini tr_db.log
