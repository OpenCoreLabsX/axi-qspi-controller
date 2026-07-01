`timescale 1ns/1ps

module axi_qspi_tb_top;
  import uvm_pkg::*;
  import axi_qspi_pkg::*;
  import axi_qspi_uvm_pkg::*;

  bit aclk;

  always #5 aclk = ~aclk;

  axi_qspi_axi_if qspi_if(.aclk(aclk));

  axi_qspi_wrapper dut (
    .i_qspi_aclk       (aclk),
    .i_qspi_aresetn    (qspi_if.aresetn),
    .i_qspi_s_awaddr   (qspi_if.s_awaddr),
    .i_qspi_s_awlen    (qspi_if.s_awlen),
    .i_qspi_s_awsize   (qspi_if.s_awsize),
    .i_qspi_s_awburst  (qspi_if.s_awburst),
    .i_qspi_s_awvalid  (qspi_if.s_awvalid),
    .o_qspi_s_awready  (qspi_if.s_awready),
    .i_qspi_s_wdata    (qspi_if.s_wdata),
    .i_qspi_s_wstrb    (qspi_if.s_wstrb),
    .i_qspi_s_wlast    (qspi_if.s_wlast),
    .i_qspi_s_wvalid   (qspi_if.s_wvalid),
    .o_qspi_s_wready   (qspi_if.s_wready),
    .o_qspi_s_bresp    (qspi_if.s_bresp),
    .o_qspi_s_bvalid   (qspi_if.s_bvalid),
    .i_qspi_s_bready   (qspi_if.s_bready),
    .i_qspi_s_araddr   (qspi_if.s_araddr),
    .i_qspi_s_arlen    (qspi_if.s_arlen),
    .i_qspi_s_arsize   (qspi_if.s_arsize),
    .i_qspi_s_arburst  (qspi_if.s_arburst),
    .i_qspi_s_arvalid  (qspi_if.s_arvalid),
    .o_qspi_s_arready  (qspi_if.s_arready),
    .o_qspi_s_rdata    (qspi_if.s_rdata),
    .o_qspi_s_rresp    (qspi_if.s_rresp),
    .o_qspi_s_rlast    (qspi_if.s_rlast),
    .o_qspi_s_rvalid   (qspi_if.s_rvalid),
    .i_qspi_s_rready   (qspi_if.s_rready),
    .i_qspi_m_araddr   (qspi_if.m_araddr),
    .i_qspi_m_arlen    (qspi_if.m_arlen),
    .i_qspi_m_arsize   (qspi_if.m_arsize),
    .i_qspi_m_arburst  (qspi_if.m_arburst),
    .i_qspi_m_arvalid  (qspi_if.m_arvalid),
    .o_qspi_m_arready  (qspi_if.m_arready),
    .o_qspi_m_rdata    (qspi_if.m_rdata),
    .o_qspi_m_rresp    (qspi_if.m_rresp),
    .o_qspi_m_rlast    (qspi_if.m_rlast),
    .o_qspi_m_rvalid   (qspi_if.m_rvalid),
    .i_qspi_m_rready   (qspi_if.m_rready),
    .o_qspi_sclk       (qspi_if.qspi_sclk),
    .o_qspi_cs_n       (qspi_if.qspi_cs_n),
    .i_qspi_io_i       (qspi_if.qspi_io_i),
    .o_qspi_io_o       (qspi_if.qspi_io_o),
    .o_qspi_io_oe      (qspi_if.qspi_io_oe),
    .o_qspi_irq        (qspi_if.irq)
  );

  initial begin
    qspi_if.init_master();
    qspi_if.aresetn = 1'b0;
  end

  initial begin
    uvm_config_db#(virtual axi_qspi_axi_if)::set(null, "uvm_test_top*", "vif", qspi_if);
    uvm_config_db#(virtual axi_qspi_axi_if)::set(null, "uvm_test_top.env.agent*", "vif", qspi_if);
    run_test();
  end
endmodule
