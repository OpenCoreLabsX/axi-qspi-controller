module axi_qspi_mem_interface
  import axi_qspi_pkg::*;
#(
  parameter int C_M_AXI_DATA_WIDTH = 32,
  parameter int C_M_AXI_ADDR_WIDTH = 32
)
(
  input  logic                              i_qspi_aclk,
  input  logic                              i_qspi_aresetn,

  input  logic [C_M_AXI_ADDR_WIDTH-1:0]     i_qspi_araddr,
  input  logic [7:0]                        i_qspi_arlen,
  input  logic [2:0]                        i_qspi_arsize,
  input  logic [1:0]                        i_qspi_arburst,
  input  logic                              i_qspi_arvalid,
  output logic                              o_qspi_arready,

  output logic [C_M_AXI_DATA_WIDTH-1:0]     o_qspi_rdata,
  output logic [1:0]                        o_qspi_rresp,
  output logic                              o_qspi_rlast,
  output logic                              o_qspi_rvalid,
  input  logic                              i_qspi_rready,

  input  logic [1:0]                        i_qspi_cfg_mode,
  input  logic [15:0]                       i_qspi_cfg_clkdiv,
  input  logic [7:0]                        i_qspi_cfg_dummy_cycles,
  input  logic                              i_qspi_xip_enable,
  input  logic [31:0]                       i_qspi_xip_base,
  input  logic [31:0]                       i_qspi_xip_mask,
  input  logic [7:0]                        i_qspi_xip_cmd,
  input  logic                              i_qspi_xip_mode_byte_en,
  input  logic [7:0]                        i_qspi_xip_mode_byte,

  output logic                              o_qspi_mem_start,
  output logic [1:0]                        o_qspi_mem_mode,
  output logic [7:0]                        o_qspi_mem_cmd,
  output logic [31:0]                       o_qspi_mem_addr,
  output logic                              o_qspi_mem_addr_mode_en,
  output logic                              o_qspi_mem_mode_byte_en,
  output logic [7:0]                        o_qspi_mem_mode_byte,
  output logic [7:0]                        o_qspi_mem_dummy_cycles,
  output logic [15:0]                       o_qspi_mem_len,
  output logic [15:0]                       o_qspi_mem_clkdiv,

  input  logic [7:0]                        i_qspi_rx_data,
  input  logic                              i_qspi_rx_valid,
  output logic                              o_qspi_rx_ready,

  input  logic                              i_qspi_busy,
  input  logic                              i_qspi_done,
  input  logic                              i_qspi_error,
  output logic                              o_qspi_mem_active
);

  typedef enum logic [1:0] {
    MEM_ST_IDLE,
    MEM_ST_START,
    MEM_ST_DATA,
    MEM_ST_DONE
  } mem_state_e;

  mem_state_e r_state;
  logic [31:0] r_addr;
  logic [7:0]  r_beat_left;
  logic [7:0]  r_beat_idx;
  logic [1:0]  r_byte_idx;
  logic [31:0] r_word;
  logic        r_start;
  logic        w_rx_take;
  logic        w_xip_hit;
  logic [31:0] w_flash_addr;
  logic [15:0] w_mem_byte_len;

  assign w_xip_hit = i_qspi_xip_enable &&
                     ((i_qspi_araddr & i_qspi_xip_mask[C_M_AXI_ADDR_WIDTH-1:0]) ==
                      (i_qspi_xip_base[C_M_AXI_ADDR_WIDTH-1:0] & i_qspi_xip_mask[C_M_AXI_ADDR_WIDTH-1:0]));
  assign w_flash_addr = i_qspi_araddr[31:0] - i_qspi_xip_base;
  assign w_mem_byte_len = ({8'd0, r_beat_left} + 16'd1) << 2;
  assign o_qspi_arready = (r_state == MEM_ST_IDLE) && !i_qspi_busy;
  assign o_qspi_mem_active = (r_state != MEM_ST_IDLE);
  assign o_qspi_rx_ready = (r_state == MEM_ST_DATA) && (!o_qspi_rvalid || i_qspi_rready);
  assign w_rx_take = i_qspi_rx_valid && o_qspi_rx_ready;

  always_comb begin
    unique case (axi_qspi_mode_e'(i_qspi_cfg_mode))
      QSPI_MODE_DUAL: o_qspi_mem_cmd = (i_qspi_xip_cmd == 8'd0) ? QSPI_CMD_READ_DUAL : i_qspi_xip_cmd;
      QSPI_MODE_QUAD: begin
        if (i_qspi_xip_cmd != 8'd0) begin
          o_qspi_mem_cmd = i_qspi_xip_cmd;
        end else if (i_qspi_xip_mode_byte_en) begin
          o_qspi_mem_cmd = QSPI_CMD_READ_QUAD_IO;
        end else begin
          o_qspi_mem_cmd = QSPI_CMD_READ_QUAD;
        end
      end
      default       : o_qspi_mem_cmd = (i_qspi_xip_cmd == 8'd0) ? QSPI_CMD_READ_SPI  : i_qspi_xip_cmd;
    endcase
  end

  assign o_qspi_mem_mode         = i_qspi_cfg_mode;
  assign o_qspi_mem_addr         = r_addr;
  assign o_qspi_mem_addr_mode_en = (axi_qspi_mode_e'(i_qspi_cfg_mode) == QSPI_MODE_QUAD) &&
                                   (((i_qspi_xip_cmd == 8'd0) && i_qspi_xip_mode_byte_en) ||
                                    (i_qspi_xip_cmd == QSPI_CMD_READ_QUAD_IO));
  assign o_qspi_mem_mode_byte_en = i_qspi_xip_mode_byte_en && (axi_qspi_mode_e'(i_qspi_cfg_mode) == QSPI_MODE_QUAD);
  assign o_qspi_mem_mode_byte    = i_qspi_xip_mode_byte;
  assign o_qspi_mem_dummy_cycles = i_qspi_cfg_dummy_cycles;
  assign o_qspi_mem_len          = w_mem_byte_len;
  assign o_qspi_mem_clkdiv       = i_qspi_cfg_clkdiv;
  assign o_qspi_mem_start        = r_start;

  always_ff @(posedge i_qspi_aclk or negedge i_qspi_aresetn) begin
    if (!i_qspi_aresetn) begin
      r_state       <= MEM_ST_IDLE;
      r_addr        <= 32'd0;
      r_beat_left   <= 8'd0;
      r_beat_idx    <= 8'd0;
      r_byte_idx    <= 2'd0;
      r_word        <= 32'd0;
      r_start       <= 1'b0;
      o_qspi_rdata  <= '0;
      o_qspi_rresp  <= 2'b00;
      o_qspi_rlast  <= 1'b0;
      o_qspi_rvalid <= 1'b0;
    end else begin
      r_start <= 1'b0;

      if (o_qspi_rvalid && i_qspi_rready) begin
        o_qspi_rvalid <= 1'b0;
        o_qspi_rlast  <= 1'b0;
      end

      unique case (r_state)
        MEM_ST_IDLE: begin
          if (i_qspi_arvalid && o_qspi_arready) begin
            if (w_xip_hit) begin
              r_addr      <= w_flash_addr;
              r_beat_left <= i_qspi_arlen;
              r_beat_idx  <= 8'd0;
              r_byte_idx  <= 2'd0;
              r_word      <= 32'd0;
              r_state     <= MEM_ST_START;
            end else begin
              o_qspi_rdata  <= '0;
              o_qspi_rresp  <= 2'b11;
              o_qspi_rvalid <= 1'b1;
              o_qspi_rlast  <= 1'b1;
              r_state       <= MEM_ST_DONE;
            end
          end
        end

        MEM_ST_START: begin
          r_start <= 1'b1;
          r_state <= MEM_ST_DATA;
        end

        MEM_ST_DATA: begin
          if (i_qspi_error) begin
            o_qspi_rresp  <= 2'b10;
            o_qspi_rvalid <= 1'b1;
            o_qspi_rlast  <= 1'b1;
            r_state       <= MEM_ST_DONE;
          end else if (w_rx_take) begin
            unique case (r_byte_idx)
              2'd0: r_word[31:24] <= i_qspi_rx_data;
              2'd1: r_word[23:16] <= i_qspi_rx_data;
              2'd2: r_word[15:8]  <= i_qspi_rx_data;
              default: begin
                o_qspi_rdata  <= {r_word[31:8], i_qspi_rx_data};
                o_qspi_rresp  <= 2'b00;
                o_qspi_rvalid <= 1'b1;
                o_qspi_rlast  <= (r_beat_left == 8'd0);
                r_beat_idx    <= r_beat_idx + 8'd1;
                if (r_beat_left == 8'd0) begin
                  r_state <= MEM_ST_DONE;
                end else begin
                  r_beat_left <= r_beat_left - 8'd1;
                end
              end
            endcase
            r_byte_idx <= r_byte_idx + 2'd1;
          end else if (i_qspi_done && (r_beat_left != 8'd0)) begin
            o_qspi_rresp  <= 2'b10;
            o_qspi_rvalid <= 1'b1;
            o_qspi_rlast  <= 1'b1;
            r_state       <= MEM_ST_DONE;
          end
        end

        MEM_ST_DONE: begin
          if (!o_qspi_rvalid || i_qspi_rready) begin
            r_state <= MEM_ST_IDLE;
          end
        end

        default: begin
          r_state <= MEM_ST_IDLE;
        end
      endcase
    end
  end

endmodule
