module axi_qspi_wrapper
  import axi_qspi_pkg::*;
#(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8,
  parameter int C_M_AXI_DATA_WIDTH = 32,
  parameter int C_M_AXI_ADDR_WIDTH = 32
)
(
  input  logic                                i_qspi_aclk,
  input  logic                                i_qspi_aresetn,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]       i_qspi_s_awaddr,
  input  logic [7:0]                          i_qspi_s_awlen,
  input  logic [2:0]                          i_qspi_s_awsize,
  input  logic [1:0]                          i_qspi_s_awburst,
  input  logic                                i_qspi_s_awvalid,
  output logic                                o_qspi_s_awready,
  input  logic [C_S_AXI_DATA_WIDTH-1:0]       i_qspi_s_wdata,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]   i_qspi_s_wstrb,
  input  logic                                i_qspi_s_wlast,
  input  logic                                i_qspi_s_wvalid,
  output logic                                o_qspi_s_wready,
  output logic [1:0]                          o_qspi_s_bresp,
  output logic                                o_qspi_s_bvalid,
  input  logic                                i_qspi_s_bready,
  input  logic [C_S_AXI_ADDR_WIDTH-1:0]       i_qspi_s_araddr,
  input  logic [7:0]                          i_qspi_s_arlen,
  input  logic [2:0]                          i_qspi_s_arsize,
  input  logic [1:0]                          i_qspi_s_arburst,
  input  logic                                i_qspi_s_arvalid,
  output logic                                o_qspi_s_arready,
  output logic [C_S_AXI_DATA_WIDTH-1:0]       o_qspi_s_rdata,
  output logic [1:0]                          o_qspi_s_rresp,
  output logic                                o_qspi_s_rlast,
  output logic                                o_qspi_s_rvalid,
  input  logic                                i_qspi_s_rready,

  input  logic [C_M_AXI_ADDR_WIDTH-1:0]       i_qspi_m_araddr,
  input  logic [7:0]                          i_qspi_m_arlen,
  input  logic [2:0]                          i_qspi_m_arsize,
  input  logic [1:0]                          i_qspi_m_arburst,
  input  logic                                i_qspi_m_arvalid,
  output logic                                o_qspi_m_arready,
  output logic [C_M_AXI_DATA_WIDTH-1:0]       o_qspi_m_rdata,
  output logic [1:0]                          o_qspi_m_rresp,
  output logic                                o_qspi_m_rlast,
  output logic                                o_qspi_m_rvalid,
  input  logic                                i_qspi_m_rready,

  output logic                                o_qspi_sclk,
  output logic                                o_qspi_cs_n,
  input  logic [3:0]                          i_qspi_io_i,
  output logic [3:0]                          o_qspi_io_o,
  output logic [3:0]                          o_qspi_io_oe,
  output logic                                o_qspi_irq
);

  logic        w_cfg_start;
  logic [1:0]  w_cfg_op;
  logic [1:0]  w_cfg_mode;
  logic [7:0]  w_cfg_cmd;
  logic [31:0] w_cfg_addr;
  logic [7:0]  w_cfg_dummy;
  logic [15:0] w_cfg_len;
  logic [15:0] w_cfg_clkdiv;
  logic        w_cfg_xip_enable;
  logic [31:0] w_cfg_xip_base;
  logic [31:0] w_cfg_xip_mask;
  logic [7:0]  w_cfg_xip_cmd;
  logic        w_cfg_xip_mode_byte_en;
  logic [7:0]  w_cfg_xip_mode_byte;
  logic [7:0]  w_cfg_tx_data;
  logic        w_cfg_tx_valid;
  logic        w_cfg_tx_ready;
  logic        w_cfg_rx_ready;

  logic        w_mem_start;
  logic [1:0]  w_mem_mode;
  logic [7:0]  w_mem_cmd;
  logic [31:0] w_mem_addr;
  logic        w_mem_addr_mode_en;
  logic        w_mem_mode_byte_en;
  logic [7:0]  w_mem_mode_byte;
  logic [7:0]  w_mem_dummy;
  logic [15:0] w_mem_len;
  logic [15:0] w_mem_clkdiv;
  logic        w_mem_rx_ready;
  logic        w_mem_active;

  logic [7:0]  w_core_rx_data;
  logic        w_core_rx_valid;
  logic        w_core_busy;
  logic        w_core_done;
  logic        w_core_error;

  logic        w_core_start;
  logic [1:0]  w_core_op;
  logic [1:0]  w_core_mode;
  logic [7:0]  w_core_cmd;
  logic [31:0] w_core_addr;
  logic        w_core_addr_mode_en;
  logic        w_core_mode_byte_en;
  logic [7:0]  w_core_mode_byte;
  logic [7:0]  w_core_dummy;
  logic [15:0] w_core_len;
  logic [15:0] w_core_clkdiv;
  logic        w_core_rx_ready;
  logic        w_cfg_tx_ready_int;

  assign w_core_start    = w_mem_start ? 1'b1 : w_cfg_start;
  assign w_core_op       = w_mem_start ? QSPI_OP_READ : w_cfg_op;
  assign w_core_mode     = w_mem_start ? w_mem_mode : w_cfg_mode;
  assign w_core_cmd      = w_mem_start ? w_mem_cmd : w_cfg_cmd;
  assign w_core_addr     = w_mem_start ? w_mem_addr : w_cfg_addr;
  assign w_core_addr_mode_en = w_mem_start ? w_mem_addr_mode_en : 1'b0;
  assign w_core_mode_byte_en = w_mem_start ? w_mem_mode_byte_en : 1'b0;
  assign w_core_mode_byte    = w_mem_start ? w_mem_mode_byte : QSPI_CONT_READ_MODE;
  assign w_core_dummy    = w_mem_start ? w_mem_dummy : w_cfg_dummy;
  assign w_core_len      = w_mem_start ? w_mem_len : w_cfg_len;
  assign w_core_clkdiv   = w_mem_start ? w_mem_clkdiv : w_cfg_clkdiv;
  assign w_core_rx_ready = w_mem_active ? w_mem_rx_ready : w_cfg_rx_ready;
  assign w_cfg_tx_ready  = w_mem_active ? 1'b0 : w_cfg_tx_ready_int;

  axi_qspi_axi4_interface #(
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH)
  ) u_qspi_axi4_if (
    .i_qspi_aclk        (i_qspi_aclk),
    .i_qspi_aresetn     (i_qspi_aresetn),
    .i_qspi_awaddr      (i_qspi_s_awaddr),
    .i_qspi_awlen       (i_qspi_s_awlen),
    .i_qspi_awsize      (i_qspi_s_awsize),
    .i_qspi_awburst     (i_qspi_s_awburst),
    .i_qspi_awvalid     (i_qspi_s_awvalid),
    .o_qspi_awready     (o_qspi_s_awready),
    .i_qspi_wdata       (i_qspi_s_wdata),
    .i_qspi_wstrb       (i_qspi_s_wstrb),
    .i_qspi_wlast       (i_qspi_s_wlast),
    .i_qspi_wvalid      (i_qspi_s_wvalid),
    .o_qspi_wready      (o_qspi_s_wready),
    .o_qspi_bresp       (o_qspi_s_bresp),
    .o_qspi_bvalid      (o_qspi_s_bvalid),
    .i_qspi_bready      (i_qspi_s_bready),
    .i_qspi_araddr      (i_qspi_s_araddr),
    .i_qspi_arlen       (i_qspi_s_arlen),
    .i_qspi_arsize      (i_qspi_s_arsize),
    .i_qspi_arburst     (i_qspi_s_arburst),
    .i_qspi_arvalid     (i_qspi_s_arvalid),
    .o_qspi_arready     (o_qspi_s_arready),
    .o_qspi_rdata       (o_qspi_s_rdata),
    .o_qspi_rresp       (o_qspi_s_rresp),
    .o_qspi_rlast       (o_qspi_s_rlast),
    .o_qspi_rvalid      (o_qspi_s_rvalid),
    .i_qspi_rready      (i_qspi_s_rready),
    .o_qspi_start       (w_cfg_start),
    .o_qspi_op          (w_cfg_op),
    .o_qspi_mode        (w_cfg_mode),
    .o_qspi_cmd         (w_cfg_cmd),
    .o_qspi_addr        (w_cfg_addr),
    .o_qspi_dummy_cycles(w_cfg_dummy),
    .o_qspi_data_len    (w_cfg_len),
    .o_qspi_clkdiv      (w_cfg_clkdiv),
    .o_qspi_tx_data     (w_cfg_tx_data),
    .o_qspi_tx_valid    (w_cfg_tx_valid),
    .i_qspi_tx_ready    (w_cfg_tx_ready),
    .i_qspi_rx_data     (w_core_rx_data),
    .i_qspi_rx_valid    (w_core_rx_valid && !w_mem_active),
    .o_qspi_rx_ready    (w_cfg_rx_ready),
    .i_qspi_busy        (w_core_busy),
    .i_qspi_done        (w_core_done),
    .i_qspi_error       (w_core_error),
    .i_qspi_xip_active  (w_mem_active),
    .o_qspi_xip_enable  (w_cfg_xip_enable),
    .o_qspi_xip_base    (w_cfg_xip_base),
    .o_qspi_xip_mask    (w_cfg_xip_mask),
    .o_qspi_xip_cmd     (w_cfg_xip_cmd),
    .o_qspi_xip_mode_byte_en(w_cfg_xip_mode_byte_en),
    .o_qspi_xip_mode_byte(w_cfg_xip_mode_byte),
    .o_qspi_irq         (o_qspi_irq)
  );

  axi_qspi_mem_interface #(
    .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH),
    .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH)
  ) u_qspi_mem_if (
    .i_qspi_aclk        (i_qspi_aclk),
    .i_qspi_aresetn     (i_qspi_aresetn),
    .i_qspi_araddr      (i_qspi_m_araddr),
    .i_qspi_arlen       (i_qspi_m_arlen),
    .i_qspi_arsize      (i_qspi_m_arsize),
    .i_qspi_arburst     (i_qspi_m_arburst),
    .i_qspi_arvalid     (i_qspi_m_arvalid),
    .o_qspi_arready     (o_qspi_m_arready),
    .o_qspi_rdata       (o_qspi_m_rdata),
    .o_qspi_rresp       (o_qspi_m_rresp),
    .o_qspi_rlast       (o_qspi_m_rlast),
    .o_qspi_rvalid      (o_qspi_m_rvalid),
    .i_qspi_rready      (i_qspi_m_rready),
    .i_qspi_cfg_mode    (w_cfg_mode),
    .i_qspi_cfg_clkdiv  (w_cfg_clkdiv),
    .i_qspi_cfg_dummy_cycles(w_cfg_dummy),
    .i_qspi_xip_enable  (w_cfg_xip_enable),
    .i_qspi_xip_base    (w_cfg_xip_base),
    .i_qspi_xip_mask    (w_cfg_xip_mask),
    .i_qspi_xip_cmd     (w_cfg_xip_cmd),
    .i_qspi_xip_mode_byte_en(w_cfg_xip_mode_byte_en),
    .i_qspi_xip_mode_byte(w_cfg_xip_mode_byte),
    .o_qspi_mem_start   (w_mem_start),
    .o_qspi_mem_mode    (w_mem_mode),
    .o_qspi_mem_cmd     (w_mem_cmd),
    .o_qspi_mem_addr    (w_mem_addr),
    .o_qspi_mem_addr_mode_en(w_mem_addr_mode_en),
    .o_qspi_mem_mode_byte_en(w_mem_mode_byte_en),
    .o_qspi_mem_mode_byte(w_mem_mode_byte),
    .o_qspi_mem_dummy_cycles(w_mem_dummy),
    .o_qspi_mem_len     (w_mem_len),
    .o_qspi_mem_clkdiv  (w_mem_clkdiv),
    .i_qspi_rx_data     (w_core_rx_data),
    .i_qspi_rx_valid    (w_core_rx_valid && w_mem_active),
    .o_qspi_rx_ready    (w_mem_rx_ready),
    .i_qspi_busy        (w_core_busy),
    .i_qspi_done        (w_core_done),
    .i_qspi_error       (w_core_error),
    .o_qspi_mem_active  (w_mem_active)
  );

  axi_qspi_core u_qspi_core (
    .i_qspi_clk         (i_qspi_aclk),
    .i_qspi_rst_n       (i_qspi_aresetn),
    .i_qspi_start       (w_core_start),
    .i_qspi_op          (w_core_op),
    .i_qspi_mode        (w_core_mode),
    .i_qspi_cmd         (w_core_cmd),
    .i_qspi_addr        (w_core_addr),
    .i_qspi_addr_bytes  (2'd3),
    .i_qspi_addr_mode_en(w_core_addr_mode_en),
    .i_qspi_mode_byte_en(w_core_mode_byte_en),
    .i_qspi_mode_byte   (w_core_mode_byte),
    .i_qspi_dummy_cycles(w_core_dummy),
    .i_qspi_data_len    (w_core_len),
    .i_qspi_clkdiv      (w_core_clkdiv),
    .i_qspi_tx_data     (w_cfg_tx_data),
    .i_qspi_tx_valid    (w_cfg_tx_valid && !w_mem_active),
    .o_qspi_tx_ready    (w_cfg_tx_ready_int),
    .o_qspi_rx_data     (w_core_rx_data),
    .o_qspi_rx_valid    (w_core_rx_valid),
    .i_qspi_rx_ready    (w_core_rx_ready),
    .o_qspi_busy        (w_core_busy),
    .o_qspi_done        (w_core_done),
    .o_qspi_error       (w_core_error),
    .o_qspi_sclk        (o_qspi_sclk),
    .o_qspi_cs_n        (o_qspi_cs_n),
    .i_qspi_io_i        (i_qspi_io_i),
    .o_qspi_io_o        (o_qspi_io_o),
    .o_qspi_io_oe       (o_qspi_io_oe)
  );

endmodule
