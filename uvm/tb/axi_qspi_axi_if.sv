interface axi_qspi_axi_if #(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8,
  parameter int C_M_AXI_DATA_WIDTH = 32,
  parameter int C_M_AXI_ADDR_WIDTH = 32
) (
  input logic aclk
);

  logic                                aresetn;

  logic [C_S_AXI_ADDR_WIDTH-1:0]       s_awaddr;
  logic [7:0]                          s_awlen;
  logic [2:0]                          s_awsize;
  logic [1:0]                          s_awburst;
  logic                                s_awvalid;
  logic                                s_awready;
  logic [C_S_AXI_DATA_WIDTH-1:0]       s_wdata;
  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_wstrb;
  logic                                s_wlast;
  logic                                s_wvalid;
  logic                                s_wready;
  logic [1:0]                          s_bresp;
  logic                                s_bvalid;
  logic                                s_bready;
  logic [C_S_AXI_ADDR_WIDTH-1:0]       s_araddr;
  logic [7:0]                          s_arlen;
  logic [2:0]                          s_arsize;
  logic [1:0]                          s_arburst;
  logic                                s_arvalid;
  logic                                s_arready;
  logic [C_S_AXI_DATA_WIDTH-1:0]       s_rdata;
  logic [1:0]                          s_rresp;
  logic                                s_rlast;
  logic                                s_rvalid;
  logic                                s_rready;

  logic [C_M_AXI_ADDR_WIDTH-1:0]       m_araddr;
  logic [7:0]                          m_arlen;
  logic [2:0]                          m_arsize;
  logic [1:0]                          m_arburst;
  logic                                m_arvalid;
  logic                                m_arready;
  logic [C_M_AXI_DATA_WIDTH-1:0]       m_rdata;
  logic [1:0]                          m_rresp;
  logic                                m_rlast;
  logic                                m_rvalid;
  logic                                m_rready;

  logic                                qspi_sclk;
  logic                                qspi_cs_n;
  logic [3:0]                          qspi_io_i;
  logic [3:0]                          qspi_io_o;
  logic [3:0]                          qspi_io_oe;
  logic                                irq;

  task automatic init_master();
    s_awaddr  <= '0;
    s_awlen   <= 8'd0;
    s_awsize  <= 3'd2;
    s_awburst <= 2'd1;
    s_awvalid <= 1'b0;
    s_wdata   <= '0;
    s_wstrb   <= '0;
    s_wlast   <= 1'b1;
    s_wvalid  <= 1'b0;
    s_bready  <= 1'b0;
    s_araddr  <= '0;
    s_arlen   <= 8'd0;
    s_arsize  <= 3'd2;
    s_arburst <= 2'd1;
    s_arvalid <= 1'b0;
    s_rready  <= 1'b0;

    m_araddr  <= '0;
    m_arlen   <= 8'd0;
    m_arsize  <= 3'd2;
    m_arburst <= 2'd1;
    m_arvalid <= 1'b0;
    m_rready  <= 1'b0;

    qspi_io_i <= 4'hF;
  endtask

endinterface
