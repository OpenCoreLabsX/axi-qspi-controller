`include "axi_qspi_defines.svh"

module axi_qspi_axi4_interface
  import axi_qspi_pkg::*;
#(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8,
  parameter int FIFO_DEPTH         = 16
)
(
  input  logic                              i_qspi_aclk,
  input  logic                              i_qspi_aresetn,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]     i_qspi_awaddr,
  input  logic [7:0]                        i_qspi_awlen,
  input  logic [2:0]                        i_qspi_awsize,
  input  logic [1:0]                        i_qspi_awburst,
  input  logic                              i_qspi_awvalid,
  output logic                              o_qspi_awready,

  input  logic [C_S_AXI_DATA_WIDTH-1:0]     i_qspi_wdata,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] i_qspi_wstrb,
  input  logic                              i_qspi_wlast,
  input  logic                              i_qspi_wvalid,
  output logic                              o_qspi_wready,

  output logic [1:0]                        o_qspi_bresp,
  output logic                              o_qspi_bvalid,
  input  logic                              i_qspi_bready,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]     i_qspi_araddr,
  input  logic [7:0]                        i_qspi_arlen,
  input  logic [2:0]                        i_qspi_arsize,
  input  logic [1:0]                        i_qspi_arburst,
  input  logic                              i_qspi_arvalid,
  output logic                              o_qspi_arready,

  output logic [C_S_AXI_DATA_WIDTH-1:0]     o_qspi_rdata,
  output logic [1:0]                        o_qspi_rresp,
  output logic                              o_qspi_rlast,
  output logic                              o_qspi_rvalid,
  input  logic                              i_qspi_rready,

  output logic                              o_qspi_start,
  output logic [1:0]                        o_qspi_op,
  output logic [1:0]                        o_qspi_mode,
  output logic [7:0]                        o_qspi_cmd,
  output logic [31:0]                       o_qspi_addr,
  output logic [7:0]                        o_qspi_dummy_cycles,
  output logic [15:0]                       o_qspi_data_len,
  output logic [15:0]                       o_qspi_clkdiv,

  output logic [7:0]                        o_qspi_tx_data,
  output logic                              o_qspi_tx_valid,
  input  logic                              i_qspi_tx_ready,
  input  logic [7:0]                        i_qspi_rx_data,
  input  logic                              i_qspi_rx_valid,
  output logic                              o_qspi_rx_ready,

  input  logic                              i_qspi_busy,
  input  logic                              i_qspi_done,
  input  logic                              i_qspi_error,
  input  logic                              i_qspi_xip_active,

  output logic                              o_qspi_xip_enable,
  output logic [31:0]                       o_qspi_xip_base,
  output logic [31:0]                       o_qspi_xip_mask,
  output logic [7:0]                        o_qspi_xip_cmd,
  output logic                              o_qspi_xip_mode_byte_en,
  output logic [7:0]                        o_qspi_xip_mode_byte,

  output logic                              o_qspi_irq
);

  logic [31:0] r_ctrl;
  logic [31:0] r_clkdiv;
  logic [31:0] r_mode;
  logic [31:0] r_cmd;
  logic [31:0] r_addr;
  logic [31:0] r_len;
  logic [31:0] r_dummy;
  logic [31:0] r_irq_en;
  logic [31:0] r_irq_stat;
  logic [31:0] r_xip_ctrl;
  logic [31:0] r_xip_base;
  logic [31:0] r_xip_mask;
  logic [31:0] r_xip_cmd;
  logic [31:0] r_xip_mode;
  logic [31:0] r_rdata;
  logic        r_start_d;

  // ── Write-channel state ──────────────────────────────────────────────
  logic        r_aw_valid;
  logic [C_S_AXI_ADDR_WIDTH-1:0] r_awaddr;
  logic [7:0]  r_awlen;
  logic [2:0]  r_awsize;
  logic [1:0]  r_awburst;
  logic        r_aw_err;     // latched: this AW is unsupported
  logic [7:0]  r_wr_cnt;     // W-beat drain counter
  logic        r_wr_drain;   // draining remaining W beats for burst error
  logic        r_w_valid;
  logic [C_S_AXI_DATA_WIDTH-1:0] r_wdata;
  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] r_wstrb;
  logic        r_wlast;

  logic        w_wr_en;
  logic        w_aw_fire;
  logic        w_w_fire;
  logic        w_wr_ok;
  logic [31:0] w_wr_data;
  logic        w_wr_addr_valid;

  // ── Read-channel state ───────────────────────────────────────────────
  logic [7:0]  r_rd_cnt;     // remaining R beats to send
  logic        r_rd_active;  // multi-beat read in progress
  logic        r_rd_err;     // latched: this AR is unsupported
  logic        w_rd_fire;
  logic        w_rd_ok;
  logic        w_rd_addr_valid;

  // ── FIFO wires ───────────────────────────────────────────────────────
  logic        w_tx_fifo_wr;
  logic        w_tx_fifo_full;
  logic        w_tx_fifo_empty;
  logic        w_tx_fifo_valid;
  logic        w_tx_fifo_pop;
  logic [7:0]  w_tx_fifo_data;
  logic        w_rx_fifo_wr;
  logic        w_rx_fifo_full;
  logic        w_rx_fifo_empty;
  logic        w_rx_fifo_valid;
  logic        w_rx_fifo_pop;
  logic [7:0]  w_rx_fifo_data;
  logic        w_fifo_clear;

  // ────────────────────────────────────────────────────────────────────
  // Write address-decode: valid register address for writes
  // ────────────────────────────────────────────────────────────────────
  always_comb begin
    unique case (r_awaddr)
      AXI_QSPI_ADDR_CTRL,
      AXI_QSPI_ADDR_CLKDIV,
      AXI_QSPI_ADDR_MODE,
      AXI_QSPI_ADDR_CMD,
      AXI_QSPI_ADDR_FLASH_ADDR,
      AXI_QSPI_ADDR_LEN,
      AXI_QSPI_ADDR_DUMMY,
      AXI_QSPI_ADDR_TXDATA,
      AXI_QSPI_ADDR_IRQ_EN,
      AXI_QSPI_ADDR_IRQ_STAT,
      AXI_QSPI_ADDR_XIP_CTRL,
      AXI_QSPI_ADDR_XIP_BASE,
      AXI_QSPI_ADDR_XIP_MASK,
      AXI_QSPI_ADDR_XIP_CMD,
      AXI_QSPI_ADDR_XIP_MODE  : w_wr_addr_valid = 1'b1;
      default                  : w_wr_addr_valid = 1'b0;
    endcase
  end

  // ────────────────────────────────────────────────────────────────────
  // Write channel handshake
  //   • Accept AW when idle (no pending AW, no pending B, not draining).
  //   • Accept W beats: during normal single-beat flow OR during drain.
  //   • For single-beat OK writes: capture AW+W, issue BRESP immediately.
  //   • For unsupported writes (burst / bad size / bad addr): drain all
  //     W beats first, then issue SLVERR on B channel.
  // ────────────────────────────────────────────────────────────────────
  assign o_qspi_awready = !r_aw_valid && !o_qspi_bvalid && !r_wr_drain;
  assign o_qspi_wready  = (r_wr_drain) ? 1'b1 :       // drain: always accept W
                           (!r_w_valid && !o_qspi_bvalid && !r_wr_drain);
  assign w_aw_fire      = i_qspi_awvalid && o_qspi_awready;
  assign w_w_fire       = i_qspi_wvalid && o_qspi_wready;

  // Single-beat write is ready to commit when both AW and W are captured
  // and we are NOT in a drain cycle (drain handles its own BRESP).
  assign w_wr_en        = r_aw_valid && r_w_valid && !o_qspi_bvalid && !r_wr_drain;

  // A write is OK only when: single beat, 32-bit, non-reserved burst,
  // wlast asserted, and the address decodes to a valid register.
  assign w_wr_ok        = (r_awlen == 8'd0) && (r_awsize == 3'd2) &&
                          (r_awburst != 2'b11) && r_wlast && w_wr_addr_valid;
  assign w_wr_data      = r_wdata[31:0];

  always_ff @(posedge i_qspi_aclk or negedge i_qspi_aresetn) begin
    if (!i_qspi_aresetn) begin
      o_qspi_bvalid <= 1'b0;
      o_qspi_bresp  <= 2'b00;
      r_aw_valid    <= 1'b0;
      r_awaddr      <= '0;
      r_awlen       <= 8'd0;
      r_awsize      <= 3'd0;
      r_awburst     <= 2'd0;
      r_aw_err      <= 1'b0;
      r_wr_cnt      <= 8'd0;
      r_wr_drain    <= 1'b0;
      r_w_valid     <= 1'b0;
      r_wdata       <= '0;
      r_wstrb       <= '0;
      r_wlast       <= 1'b0;
    end else begin
      // ── AW capture ──
      if (w_aw_fire) begin
        r_aw_valid <= 1'b1;
        r_awaddr   <= i_qspi_awaddr;
        r_awlen    <= i_qspi_awlen;
        r_awsize   <= i_qspi_awsize;
        r_awburst  <= i_qspi_awburst;
      end

      // ── W capture (only for normal path, not drain) ──
      if (w_w_fire && !r_wr_drain) begin
        r_w_valid <= 1'b1;
        r_wdata   <= i_qspi_wdata;
        r_wstrb   <= i_qspi_wstrb;
        r_wlast   <= i_qspi_wlast;
      end

      // ── Normal single-beat commit or enter drain ──
      if (w_wr_en) begin
        if (w_wr_ok) begin
          // Good single-beat write → respond OKAY immediately
          o_qspi_bvalid <= 1'b1;
          o_qspi_bresp  <= 2'b00;
          r_aw_valid    <= 1'b0;
          r_w_valid     <= 1'b0;
        end else begin
          // Unsupported access detected.
          // If awlen==0 (single beat, but bad size/burst/addr),
          // we already have the only W beat → respond SLVERR now.
          // If awlen>0 (burst), enter drain to consume remaining W beats.
          if (r_awlen == 8'd0) begin
            // Single beat error → SLVERR immediately
            o_qspi_bvalid <= 1'b1;
            o_qspi_bresp  <= 2'b10;
            r_aw_valid    <= 1'b0;
            r_w_valid     <= 1'b0;
          end else begin
            // Burst error → drain remaining W beats
            r_wr_drain <= 1'b1;
            r_aw_err   <= 1'b1;
            r_wr_cnt   <= r_awlen;  // already consumed 1 beat, awlen more remain
            r_w_valid  <= 1'b0;
            r_aw_valid <= 1'b0;
          end
        end
      end

      // ── Drain path: consume remaining W beats ──
      if (r_wr_drain && w_w_fire) begin
        if (i_qspi_wlast || (r_wr_cnt == 8'd1)) begin
          // Last beat consumed → issue SLVERR
          o_qspi_bvalid <= 1'b1;
          o_qspi_bresp  <= 2'b10;
          r_wr_drain    <= 1'b0;
          r_aw_err      <= 1'b0;
          r_wr_cnt      <= 8'd0;
        end else begin
          r_wr_cnt <= r_wr_cnt - 8'd1;
        end
      end

      // ── B handshake complete ──
      if (o_qspi_bvalid && i_qspi_bready) begin
        o_qspi_bvalid <= 1'b0;
      end
    end
  end

  // ────────────────────────────────────────────────────────────────────
  // Register writes (only for valid single-beat accesses)
  // ────────────────────────────────────────────────────────────────────
  always_ff @(posedge i_qspi_aclk or negedge i_qspi_aresetn) begin
    if (!i_qspi_aresetn) begin
      r_ctrl     <= 32'd0;
      r_clkdiv   <= 32'd3;
      r_mode     <= 32'd0;
      r_cmd      <= {24'd0, QSPI_CMD_READ_SPI};
      r_addr     <= 32'd0;
      r_len      <= 32'd0;
      r_dummy    <= 32'd8;
      r_irq_en   <= 32'd0;
      r_irq_stat <= 32'd0;
      r_xip_ctrl <= 32'd0;
      r_xip_base <= 32'd0;
      r_xip_mask <= 32'hFF00_0000;
      r_xip_cmd  <= {24'd0, QSPI_CMD_READ_SPI};
      r_xip_mode <= {23'd0, 1'b1, QSPI_CONT_READ_MODE};
      r_start_d  <= 1'b0;
    end else begin
      r_start_d <= r_ctrl[0];

      if (o_qspi_start) begin
        r_ctrl[0] <= 1'b0;
      end

      if (i_qspi_done) begin
        r_irq_stat[0] <= 1'b1;
      end
      if (i_qspi_error || w_tx_fifo_full || w_rx_fifo_full) begin
        r_irq_stat[1] <= 1'b1;
      end

      if (w_wr_en && w_wr_ok) begin
        unique case (r_awaddr)
          AXI_QSPI_ADDR_CTRL       : r_ctrl   <= apply_wstrb(r_ctrl, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_CLKDIV     : r_clkdiv <= apply_wstrb(r_clkdiv, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_MODE       : r_mode   <= apply_wstrb(r_mode, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_CMD        : r_cmd    <= apply_wstrb(r_cmd, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_FLASH_ADDR : r_addr   <= apply_wstrb(r_addr, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_LEN        : r_len    <= apply_wstrb(r_len, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_DUMMY      : r_dummy  <= apply_wstrb(r_dummy, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_IRQ_EN     : r_irq_en <= apply_wstrb(r_irq_en, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_IRQ_STAT   : r_irq_stat <= r_irq_stat & ~apply_wstrb(32'd0, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_XIP_CTRL   : r_xip_ctrl <= apply_wstrb(r_xip_ctrl, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_XIP_BASE   : r_xip_base <= apply_wstrb(r_xip_base, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_XIP_MASK   : r_xip_mask <= apply_wstrb(r_xip_mask, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_XIP_CMD    : r_xip_cmd  <= apply_wstrb(r_xip_cmd, w_wr_data, r_wstrb);
          AXI_QSPI_ADDR_XIP_MODE   : r_xip_mode <= apply_wstrb(r_xip_mode, w_wr_data, r_wstrb);
          default                  : ;
        endcase
      end
    end
  end

  assign o_qspi_start        = r_ctrl[0] & ~r_start_d & !i_qspi_busy;
  assign o_qspi_op           = r_ctrl[2:1];
  assign o_qspi_mode         = r_mode[1:0];
  assign o_qspi_cmd          = r_cmd[7:0];
  assign o_qspi_addr         = r_addr;
  assign o_qspi_dummy_cycles = r_dummy[7:0];
  assign o_qspi_data_len     = r_len[15:0];
  assign o_qspi_clkdiv       = r_clkdiv[15:0];
  assign o_qspi_irq          = |(r_irq_stat & r_irq_en);
  assign o_qspi_xip_enable   = r_xip_ctrl[0];
  assign o_qspi_xip_base     = r_xip_base;
  assign o_qspi_xip_mask     = r_xip_mask;
  assign o_qspi_xip_cmd      = r_xip_cmd[7:0];
  assign o_qspi_xip_mode_byte_en = r_xip_mode[8];
  assign o_qspi_xip_mode_byte    = r_xip_mode[7:0];
  assign w_fifo_clear        = r_ctrl[8];

  assign w_tx_fifo_wr = w_wr_en && w_wr_ok && (r_awaddr == AXI_QSPI_ADDR_TXDATA) && r_wstrb[0];
  assign w_tx_fifo_pop = i_qspi_tx_ready && w_tx_fifo_valid;
  assign o_qspi_tx_data = w_tx_fifo_data;
  assign o_qspi_tx_valid = w_tx_fifo_valid;

  axi_qspi_fifo #(
    .DATA_WIDTH      (8),
    .DEPTH           (FIFO_DEPTH)
  ) u_qspi_tx_fifo (
    .i_qspi_clk      (i_qspi_aclk),
    .i_qspi_rst_n    (i_qspi_aresetn),
    .i_qspi_clear    (w_fifo_clear),
    .i_qspi_wr_en    (w_tx_fifo_wr),
    .i_qspi_wr_data  (r_wdata[7:0]),
    .o_qspi_full     (w_tx_fifo_full),
    .i_qspi_rd_en    (w_tx_fifo_pop),
    .o_qspi_rd_data  (w_tx_fifo_data),
    .o_qspi_empty    (w_tx_fifo_empty),
    .o_qspi_valid    (w_tx_fifo_valid)
  );

  assign w_rx_fifo_wr = i_qspi_rx_valid && !w_rx_fifo_full;
  assign o_qspi_rx_ready = !w_rx_fifo_full;

  axi_qspi_fifo #(
    .DATA_WIDTH      (8),
    .DEPTH           (FIFO_DEPTH)
  ) u_qspi_rx_fifo (
    .i_qspi_clk      (i_qspi_aclk),
    .i_qspi_rst_n    (i_qspi_aresetn),
    .i_qspi_clear    (w_fifo_clear),
    .i_qspi_wr_en    (w_rx_fifo_wr),
    .i_qspi_wr_data  (i_qspi_rx_data),
    .o_qspi_full     (w_rx_fifo_full),
    .i_qspi_rd_en    (w_rx_fifo_pop),
    .o_qspi_rd_data  (w_rx_fifo_data),
    .o_qspi_empty    (w_rx_fifo_empty),
    .o_qspi_valid    (w_rx_fifo_valid)
  );

  // ────────────────────────────────────────────────────────────────────
  // Read address-decode: valid register address for reads
  // ────────────────────────────────────────────────────────────────────
  always_comb begin
    unique case (i_qspi_araddr)
      AXI_QSPI_ADDR_CTRL,
      AXI_QSPI_ADDR_STATUS,
      AXI_QSPI_ADDR_CLKDIV,
      AXI_QSPI_ADDR_MODE,
      AXI_QSPI_ADDR_CMD,
      AXI_QSPI_ADDR_FLASH_ADDR,
      AXI_QSPI_ADDR_LEN,
      AXI_QSPI_ADDR_DUMMY,
      AXI_QSPI_ADDR_RXDATA,
      AXI_QSPI_ADDR_IRQ_EN,
      AXI_QSPI_ADDR_IRQ_STAT,
      AXI_QSPI_ADDR_VERSION,
      AXI_QSPI_ADDR_XIP_CTRL,
      AXI_QSPI_ADDR_XIP_BASE,
      AXI_QSPI_ADDR_XIP_MASK,
      AXI_QSPI_ADDR_XIP_CMD,
      AXI_QSPI_ADDR_XIP_MODE  : w_rd_addr_valid = 1'b1;
      default                  : w_rd_addr_valid = 1'b0;
    endcase
  end

  // ────────────────────────────────────────────────────────────────────
  // Read channel handshake
  //   • Single-beat OK read: respond with data + OKAY + rlast.
  //   • Unsupported read (burst / bad size / bad addr): respond with
  //     arlen+1 beats of data=0, rresp=SLVERR, rlast on the final beat.
  // ────────────────────────────────────────────────────────────────────
  assign o_qspi_arready = !o_qspi_rvalid && !r_rd_active;
  assign w_rd_fire      = i_qspi_arvalid && o_qspi_arready;
  assign w_rd_ok        = (i_qspi_arlen == 8'd0) && (i_qspi_arsize == 3'd2) &&
                          (i_qspi_arburst != 2'b11) && w_rd_addr_valid;
  assign w_rx_fifo_pop  = w_rd_fire && w_rd_ok && (i_qspi_araddr == AXI_QSPI_ADDR_RXDATA) && w_rx_fifo_valid;

  always_comb begin
    r_rdata = 32'd0;
    unique case (i_qspi_araddr)
      AXI_QSPI_ADDR_CTRL       : r_rdata = r_ctrl;
      AXI_QSPI_ADDR_STATUS     : r_rdata = {26'd0, i_qspi_xip_active, w_rx_fifo_valid, w_tx_fifo_empty, i_qspi_error, r_irq_stat[0], i_qspi_busy};
      AXI_QSPI_ADDR_CLKDIV     : r_rdata = r_clkdiv;
      AXI_QSPI_ADDR_MODE       : r_rdata = r_mode;
      AXI_QSPI_ADDR_CMD        : r_rdata = r_cmd;
      AXI_QSPI_ADDR_FLASH_ADDR : r_rdata = r_addr;
      AXI_QSPI_ADDR_LEN        : r_rdata = r_len;
      AXI_QSPI_ADDR_DUMMY      : r_rdata = r_dummy;
      AXI_QSPI_ADDR_RXDATA     : r_rdata = {24'd0, w_rx_fifo_data};
      AXI_QSPI_ADDR_IRQ_EN     : r_rdata = r_irq_en;
      AXI_QSPI_ADDR_IRQ_STAT   : r_rdata = r_irq_stat;
      AXI_QSPI_ADDR_VERSION    : r_rdata = `AXI_QSPI_VERSION;
      AXI_QSPI_ADDR_XIP_CTRL   : r_rdata = r_xip_ctrl;
      AXI_QSPI_ADDR_XIP_BASE   : r_rdata = r_xip_base;
      AXI_QSPI_ADDR_XIP_MASK   : r_rdata = r_xip_mask;
      AXI_QSPI_ADDR_XIP_CMD    : r_rdata = r_xip_cmd;
      AXI_QSPI_ADDR_XIP_MODE   : r_rdata = r_xip_mode;
      default                  : r_rdata = 32'd0;
    endcase
  end

  always_ff @(posedge i_qspi_aclk or negedge i_qspi_aresetn) begin
    if (!i_qspi_aresetn) begin
      o_qspi_rvalid <= 1'b0;
      o_qspi_rdata  <= '0;
      o_qspi_rresp  <= 2'b00;
      o_qspi_rlast  <= 1'b0;
      r_rd_cnt      <= 8'd0;
      r_rd_active   <= 1'b0;
      r_rd_err      <= 1'b0;
    end else begin
      if (w_rd_fire) begin
        o_qspi_rvalid <= 1'b1;
        if (w_rd_ok) begin
          // Single-beat OK read
          o_qspi_rdata <= r_rdata;
          o_qspi_rresp <= 2'b00;
          o_qspi_rlast <= 1'b1;
        end else begin
          // Unsupported read: first beat with SLVERR
          o_qspi_rdata <= 32'd0;
          o_qspi_rresp <= 2'b10;
          if (i_qspi_arlen == 8'd0) begin
            // Single-beat error → rlast immediately
            o_qspi_rlast <= 1'b1;
          end else begin
            // Burst error → need arlen more beats after this one
            o_qspi_rlast  <= 1'b0;
            r_rd_cnt      <= i_qspi_arlen;  // arlen beats remaining after this one
            r_rd_active   <= 1'b1;
            r_rd_err      <= 1'b1;
          end
        end
      end else if (o_qspi_rvalid && i_qspi_rready) begin
        if (r_rd_active) begin
          // Multi-beat error response: send next beat
          if (r_rd_cnt == 8'd1) begin
            // Last beat
            o_qspi_rdata  <= 32'd0;
            o_qspi_rresp  <= 2'b10;
            o_qspi_rlast  <= 1'b1;
            r_rd_cnt      <= 8'd0;
            r_rd_active   <= 1'b0;
            r_rd_err      <= 1'b0;
          end else begin
            o_qspi_rdata  <= 32'd0;
            o_qspi_rresp  <= 2'b10;
            o_qspi_rlast  <= 1'b0;
            r_rd_cnt      <= r_rd_cnt - 8'd1;
          end
        end else begin
          // Single-beat response done
          o_qspi_rvalid <= 1'b0;
          o_qspi_rlast  <= 1'b0;
        end
      end
    end
  end

  function automatic logic [31:0] apply_wstrb(
    input logic [31:0] i_old_data,
    input logic [31:0] i_new_data,
    input logic [(C_S_AXI_DATA_WIDTH/8)-1:0] i_strb
  );
    logic [31:0] v_data;
    begin
      v_data = i_old_data;
      for (int i = 0; i < 4; i++) begin
        if (i_strb[i]) begin
          v_data[(i * 8) +: 8] = i_new_data[(i * 8) +: 8];
        end
      end
      apply_wstrb = v_data;
    end
  endfunction

endmodule
