package axi_qspi_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "axi_qspi_defines.svh"
  import axi_qspi_pkg::*;

  `include "axi_qspi_axi_item.sv"
  `include "axi_qspi_axi_sequencer.sv"
  `include "axi_qspi_axi_driver.sv"
  `include "axi_qspi_axi_monitor.sv"
  `include "axi_qspi_scoreboard.sv"
  `include "axi_qspi_agent.sv"
  `include "axi_qspi_env.sv"

  `include "axi_qspi_base_seq.sv"
  `include "axi_qspi_reg_smoke_seq.sv"
  `include "axi_qspi_xip_seq.sv"
  `include "axi_qspi_fifo_irq_seq.sv"
  `include "axi_qspi_axi_skew_seq.sv"
  `include "axi_qspi_slverr_seq.sv"
  `include "axi_qspi_all_seq.sv"

  `include "axi_qspi_base_test.sv"
  `include "axi_qspi_reg_test.sv"
  `include "axi_qspi_xip_test.sv"
  `include "axi_qspi_fifo_irq_test.sv"
  `include "axi_qspi_axi_skew_test.sv"
  `include "axi_qspi_slverr_test.sv"
  `include "axi_qspi_all_test.sv"
endpackage
