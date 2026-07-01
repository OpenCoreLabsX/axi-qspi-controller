module axi_qspi_core
  import axi_qspi_pkg::*;
(
  input  logic        i_qspi_clk,
  input  logic        i_qspi_rst_n,

  input  logic        i_qspi_start,
  input  logic [1:0]  i_qspi_op,
  input  logic [1:0]  i_qspi_mode,
  input  logic [7:0]  i_qspi_cmd,
  input  logic [31:0] i_qspi_addr,
  input  logic [1:0]  i_qspi_addr_bytes,
  input  logic        i_qspi_addr_mode_en,
  input  logic        i_qspi_mode_byte_en,
  input  logic [7:0]  i_qspi_mode_byte,
  input  logic [7:0]  i_qspi_dummy_cycles,
  input  logic [15:0] i_qspi_data_len,
  input  logic [15:0] i_qspi_clkdiv,

  input  logic [7:0]  i_qspi_tx_data,
  input  logic        i_qspi_tx_valid,
  output logic        o_qspi_tx_ready,

  output logic [7:0]  o_qspi_rx_data,
  output logic        o_qspi_rx_valid,
  input  logic        i_qspi_rx_ready,

  output logic        o_qspi_busy,
  output logic        o_qspi_done,
  output logic        o_qspi_error,

  output logic        o_qspi_sclk,
  output logic        o_qspi_cs_n,
  input  logic [3:0]  i_qspi_io_i,
  output logic [3:0]  o_qspi_io_o,
  output logic [3:0]  o_qspi_io_oe
);

  axi_qspi_state_e r_state;
  axi_qspi_op_e    r_op;
  axi_qspi_mode_e  r_mode;

  logic [15:0] r_clk_cnt;
  logic        w_tick;
  logic        r_sclk;
  logic        r_cs_n;
  logic [3:0]  r_io_o;
  logic [3:0]  r_io_oe;

  logic [7:0]  r_shift_tx;
  logic [7:0]  r_shift_rx;
  logic [2:0]  r_bit_cnt;
  logic [7:0]  r_dummy_cnt;
  logic [15:0] r_byte_cnt;
  logic [31:0] r_addr_shift;
  logic [1:0]  r_addr_left;
  logic        r_addr_mode_en;
  logic        r_mode_byte_en;
  logic [7:0]  r_mode_byte;
  logic [7:0]  r_rx_data;
  logic        r_rx_valid;
  logic        r_done;
  logic        r_error;
  logic        r_need_tx_byte;

  logic [2:0]  w_lanes;
  logic [2:0]  w_bit_step;
  logic [3:0]  w_sample_bits;

  assign w_tick = (r_clk_cnt == 16'd0);

  always_comb begin
    unique case (r_mode)
      QSPI_MODE_DUAL: begin
        w_lanes      = 3'd2;
        w_bit_step   = 3'd2;
        w_sample_bits = {2'b00, i_qspi_io_i[1:0]};
      end
      QSPI_MODE_QUAD: begin
        w_lanes      = 3'd4;
        w_bit_step   = 3'd4;
        w_sample_bits = i_qspi_io_i;
      end
      default: begin
        w_lanes      = 3'd1;
        w_bit_step   = 3'd1;
        w_sample_bits = {3'b000, i_qspi_io_i[1]};
      end
    endcase
  end

  always_ff @(posedge i_qspi_clk or negedge i_qspi_rst_n) begin
    if (!i_qspi_rst_n) begin
      r_clk_cnt <= 16'd0;
    end else if (!o_qspi_busy) begin
      r_clk_cnt <= i_qspi_clkdiv;
    end else if (w_tick) begin
      r_clk_cnt <= i_qspi_clkdiv;
    end else begin
      r_clk_cnt <= r_clk_cnt - 16'd1;
    end
  end

  always_ff @(posedge i_qspi_clk or negedge i_qspi_rst_n) begin
    if (!i_qspi_rst_n) begin
      r_state        <= QSPI_ST_IDLE;
      r_op           <= QSPI_OP_READ;
      r_mode         <= QSPI_MODE_SPI;
      r_sclk         <= 1'b0;
      r_cs_n         <= 1'b1;
      r_io_o         <= 4'd0;
      r_io_oe        <= 4'd0;
      r_shift_tx     <= 8'd0;
      r_shift_rx     <= 8'd0;
      r_bit_cnt      <= 3'd7;
      r_dummy_cnt    <= 8'd0;
      r_byte_cnt     <= 16'd0;
      r_addr_shift   <= 32'd0;
      r_addr_left    <= 2'd0;
      r_addr_mode_en <= 1'b0;
      r_mode_byte_en <= 1'b0;
      r_mode_byte    <= QSPI_CONT_READ_MODE;
      r_rx_data      <= 8'd0;
      r_rx_valid     <= 1'b0;
      r_done         <= 1'b0;
      r_error        <= 1'b0;
      r_need_tx_byte <= 1'b0;
    end else begin
      r_done <= 1'b0;
      if (r_rx_valid && i_qspi_rx_ready) begin
        r_rx_valid <= 1'b0;
      end

      if (i_qspi_start && (r_state == QSPI_ST_IDLE)) begin
        r_state        <= QSPI_ST_START;
        r_op           <= axi_qspi_op_e'(i_qspi_op);
        r_mode         <= axi_qspi_mode_e'(i_qspi_mode);
        r_sclk         <= 1'b0;
        r_cs_n         <= 1'b1;
        r_io_oe        <= 4'd0;
        r_shift_tx     <= i_qspi_cmd;
        r_bit_cnt      <= 3'd7;
        r_dummy_cnt    <= i_qspi_dummy_cycles;
        r_byte_cnt     <= i_qspi_data_len;
        r_addr_shift   <= i_qspi_addr;
        r_addr_left    <= (i_qspi_addr_bytes == 2'd0) ? 2'd3 : i_qspi_addr_bytes;
        r_addr_mode_en <= i_qspi_addr_mode_en;
        r_mode_byte_en <= i_qspi_mode_byte_en;
        r_mode_byte    <= i_qspi_mode_byte;
        r_error        <= 1'b0;
        r_need_tx_byte <= 1'b0;
      end else if (w_tick) begin
        unique case (r_state)
          QSPI_ST_IDLE: begin
            r_sclk  <= 1'b0;
            r_cs_n  <= 1'b1;
            r_io_oe <= 4'd0;
          end

          QSPI_ST_START: begin
            r_cs_n  <= 1'b0;
            r_sclk  <= 1'b0;
            r_io_oe <= 4'b0001;
            r_state <= QSPI_ST_CMD;
          end

          QSPI_ST_CMD: begin
            drive_single_bit();
            if (r_sclk) begin
              if (r_bit_cnt == 3'd0) begin
                load_addr_byte();
                r_state <= QSPI_ST_ADDR;
              end else begin
                r_bit_cnt <= r_bit_cnt - 3'd1;
              end
            end
          end

          QSPI_ST_ADDR: begin
            if (r_addr_mode_en) begin
              drive_mode_bits();
            end else begin
              drive_single_bit();
            end
            if (r_sclk) begin
              if ((!r_addr_mode_en && (r_bit_cnt == 3'd0)) ||
                  ( r_addr_mode_en && (r_bit_cnt < w_bit_step))) begin
                if (r_addr_left == 2'd0) begin
                  r_bit_cnt <= 3'd7;
                  if (r_mode_byte_en) begin
                    r_shift_tx <= r_mode_byte;
                    r_state    <= QSPI_ST_MODE;
                  end else if (r_dummy_cnt != 8'd0) begin
                    r_io_oe <= 4'd0;
                    r_state <= QSPI_ST_DUMMY;
                  end else if ((r_op == QSPI_OP_READ) && (r_byte_cnt != 16'd0)) begin
                    r_io_oe <= 4'd0;
                    r_state <= QSPI_ST_RX;
                  end else if (r_op == QSPI_OP_PROGRAM) begin
                    r_need_tx_byte <= 1'b1;
                    r_state        <= QSPI_ST_TX;
                  end else begin
                    r_state <= QSPI_ST_STOP;
                  end
                end else begin
                  load_addr_byte();
                end
              end else begin
                r_bit_cnt <= r_bit_cnt - 3'd1;
              end
            end
          end

          QSPI_ST_MODE: begin
            drive_mode_bits();
            if (r_sclk) begin
              if (r_bit_cnt < w_bit_step) begin
                r_bit_cnt <= 3'd7;
                if (r_dummy_cnt != 8'd0) begin
                  r_io_oe <= 4'd0;
                  r_state <= QSPI_ST_DUMMY;
                end else if ((r_op == QSPI_OP_READ) && (r_byte_cnt != 16'd0)) begin
                  r_io_oe <= 4'd0;
                  r_state <= QSPI_ST_RX;
                end else if (r_op == QSPI_OP_PROGRAM) begin
                  r_need_tx_byte <= 1'b1;
                  r_state        <= QSPI_ST_TX;
                end else begin
                  r_state <= QSPI_ST_STOP;
                end
              end else begin
                r_bit_cnt <= r_bit_cnt - w_bit_step;
              end
            end
          end

          QSPI_ST_DUMMY: begin
            r_io_oe <= 4'd0;
            r_sclk  <= ~r_sclk;
            if (r_sclk) begin
              if (r_dummy_cnt == 8'd1) begin
                r_bit_cnt <= 3'd7;
                if ((r_op == QSPI_OP_READ) && (r_byte_cnt != 16'd0)) begin
                  r_state <= QSPI_ST_RX;
                end else if (r_op == QSPI_OP_PROGRAM) begin
                  r_state <= QSPI_ST_TX;
                end else begin
                  r_state <= QSPI_ST_STOP;
                end
              end
              r_dummy_cnt <= r_dummy_cnt - 8'd1;
            end
          end

          QSPI_ST_TX: begin
            if (r_byte_cnt == 16'd0) begin
              r_state <= QSPI_ST_STOP;
            end else if (r_need_tx_byte) begin
              if (i_qspi_tx_valid) begin
                r_shift_tx     <= i_qspi_tx_data;
                r_bit_cnt      <= 3'd7;
                r_need_tx_byte <= 1'b0;
              end else begin
                r_error <= 1'b1;
                r_state <= QSPI_ST_STOP;
              end
            end else begin
              drive_mode_bits();
              if (r_sclk) begin
                if (r_bit_cnt < w_bit_step) begin
                  r_byte_cnt     <= r_byte_cnt - 16'd1;
                  r_need_tx_byte <= 1'b1;
                end else begin
                  r_bit_cnt <= r_bit_cnt - w_bit_step;
                end
              end
            end
          end

          QSPI_ST_RX: begin
            if (r_rx_valid && !i_qspi_rx_ready) begin
              r_io_oe <= 4'd0;
            end else begin
              r_io_oe <= 4'd0;
              r_sclk  <= ~r_sclk;
              if (r_sclk) begin
                sample_mode_bits();
                if (r_bit_cnt < w_bit_step) begin
                  r_rx_data  <= next_rx_byte();
                  r_rx_valid <= 1'b1;
                  r_byte_cnt <= r_byte_cnt - 16'd1;
                  r_bit_cnt  <= 3'd7;
                  if (r_byte_cnt == 16'd1) begin
                    r_state <= QSPI_ST_STOP;
                  end
                end else begin
                  r_bit_cnt <= r_bit_cnt - w_bit_step;
                end
              end
            end
          end

          QSPI_ST_STOP: begin
            r_sclk  <= 1'b0;
            r_cs_n  <= 1'b1;
            r_io_oe <= 4'd0;
            r_state <= QSPI_ST_DONE;
          end

          QSPI_ST_DONE: begin
            r_done  <= 1'b1;
            r_state <= QSPI_ST_IDLE;
          end

          default: begin
            r_state <= QSPI_ST_IDLE;
          end
        endcase
      end
    end
  end

  task automatic drive_single_bit();
    begin
      r_sclk     <= ~r_sclk;
      r_io_oe    <= 4'b0001;
      r_io_o[0]  <= r_shift_tx[r_bit_cnt];
    end
  endtask

  task automatic drive_mode_bits();
    begin
      r_sclk  <= ~r_sclk;
      r_io_oe <= (w_lanes == 3'd4) ? 4'b1111 :
                 (w_lanes == 3'd2) ? 4'b0011 : 4'b0001;
      unique case (w_lanes)
        3'd4: r_io_o <= r_shift_tx[r_bit_cnt -: 4];
        3'd2: r_io_o[1:0] <= r_shift_tx[r_bit_cnt -: 2];
        default: r_io_o[0] <= r_shift_tx[r_bit_cnt];
      endcase
    end
  endtask

  task automatic load_addr_byte();
    begin
      unique case (r_addr_left)
        2'd3: begin r_shift_tx <= r_addr_shift[23:16]; r_addr_left <= 2'd2; end
        2'd2: begin r_shift_tx <= r_addr_shift[15:8];  r_addr_left <= 2'd1; end
        default: begin r_shift_tx <= r_addr_shift[7:0]; r_addr_left <= 2'd0; end
      endcase
      r_bit_cnt <= 3'd7;
    end
  endtask

  task automatic sample_mode_bits();
    begin
      unique case (w_lanes)
        3'd4: r_shift_rx[r_bit_cnt -: 4] <= w_sample_bits;
        3'd2: r_shift_rx[r_bit_cnt -: 2] <= w_sample_bits[1:0];
        default: r_shift_rx[r_bit_cnt] <= w_sample_bits[0];
      endcase
    end
  endtask

  function automatic logic [7:0] next_rx_byte();
    logic [7:0] v_rx;
    begin
      v_rx = r_shift_rx;
      unique case (w_lanes)
        3'd4: v_rx[r_bit_cnt -: 4] = w_sample_bits;
        3'd2: v_rx[r_bit_cnt -: 2] = w_sample_bits[1:0];
        default: v_rx[r_bit_cnt] = w_sample_bits[0];
      endcase
      next_rx_byte = v_rx;
    end
  endfunction

  assign o_qspi_tx_ready = (r_state == QSPI_ST_TX) && r_need_tx_byte;
  assign o_qspi_rx_data  = r_rx_data;
  assign o_qspi_rx_valid = r_rx_valid;
  assign o_qspi_busy     = (r_state != QSPI_ST_IDLE);
  assign o_qspi_done     = r_done;
  assign o_qspi_error    = r_error;
  assign o_qspi_sclk     = r_sclk;
  assign o_qspi_cs_n     = r_cs_n;
  assign o_qspi_io_o     = r_io_o;
  assign o_qspi_io_oe    = r_io_oe;

endmodule
