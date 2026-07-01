package axi_qspi_pkg;
  typedef enum logic [1:0] {
    QSPI_MODE_SPI  = 2'd0,
    QSPI_MODE_DUAL = 2'd1,
    QSPI_MODE_QUAD = 2'd2
  } axi_qspi_mode_e;

  typedef enum logic [1:0] {
    QSPI_OP_READ    = 2'd0,
    QSPI_OP_PROGRAM = 2'd1,
    QSPI_OP_ERASE   = 2'd2
  } axi_qspi_op_e;

  typedef enum logic [3:0] {
    QSPI_ST_IDLE,
    QSPI_ST_START,
    QSPI_ST_CMD,
    QSPI_ST_ADDR,
    QSPI_ST_MODE,
    QSPI_ST_DUMMY,
    QSPI_ST_TX,
    QSPI_ST_RX,
    QSPI_ST_STOP,
    QSPI_ST_DONE
  } axi_qspi_state_e;

  localparam logic [7:0] AXI_QSPI_ADDR_CTRL       = 8'h00;
  localparam logic [7:0] AXI_QSPI_ADDR_STATUS     = 8'h04;
  localparam logic [7:0] AXI_QSPI_ADDR_CLKDIV     = 8'h08;
  localparam logic [7:0] AXI_QSPI_ADDR_MODE       = 8'h0C;
  localparam logic [7:0] AXI_QSPI_ADDR_CMD        = 8'h10;
  localparam logic [7:0] AXI_QSPI_ADDR_FLASH_ADDR = 8'h14;
  localparam logic [7:0] AXI_QSPI_ADDR_LEN        = 8'h18;
  localparam logic [7:0] AXI_QSPI_ADDR_DUMMY      = 8'h1C;
  localparam logic [7:0] AXI_QSPI_ADDR_TXDATA     = 8'h20;
  localparam logic [7:0] AXI_QSPI_ADDR_RXDATA     = 8'h24;
  localparam logic [7:0] AXI_QSPI_ADDR_IRQ_EN     = 8'h28;
  localparam logic [7:0] AXI_QSPI_ADDR_IRQ_STAT   = 8'h2C;
  localparam logic [7:0] AXI_QSPI_ADDR_VERSION    = 8'h30;
  localparam logic [7:0] AXI_QSPI_ADDR_XIP_CTRL   = 8'h34;
  localparam logic [7:0] AXI_QSPI_ADDR_XIP_BASE   = 8'h38;
  localparam logic [7:0] AXI_QSPI_ADDR_XIP_MASK   = 8'h3C;
  localparam logic [7:0] AXI_QSPI_ADDR_XIP_CMD    = 8'h40;
  localparam logic [7:0] AXI_QSPI_ADDR_XIP_MODE   = 8'h44;

  localparam logic [7:0] QSPI_CMD_READ_SPI        = 8'h0B;
  localparam logic [7:0] QSPI_CMD_READ_DUAL       = 8'h3B;
  localparam logic [7:0] QSPI_CMD_READ_QUAD       = 8'h6B;
  localparam logic [7:0] QSPI_CMD_READ_QUAD_IO    = 8'hEB;
  localparam logic [7:0] QSPI_CMD_WRITE_ENABLE    = 8'h06;
  localparam logic [7:0] QSPI_CMD_READ_STATUS     = 8'h05;
  localparam logic [7:0] QSPI_CMD_READ_CONFIG     = 8'h35;
  localparam logic [7:0] QSPI_CMD_READ_ID         = 8'h9F;
  localparam logic [7:0] QSPI_CMD_CLEAR_STATUS    = 8'h30;
  localparam logic [7:0] QSPI_CMD_PAGE_PROGRAM    = 8'h02;
  localparam logic [7:0] QSPI_CMD_QUAD_PROGRAM    = 8'h32;
  localparam logic [7:0] QSPI_CMD_SECTOR_ERASE    = 8'h20;
  localparam logic [7:0] QSPI_CONT_READ_MODE      = 8'hA0;
endpackage
