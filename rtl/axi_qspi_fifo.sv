module axi_qspi_fifo
#(
  parameter int DATA_WIDTH = 8,
  parameter int DEPTH      = 16
)
(
  input  logic                  i_qspi_clk,
  input  logic                  i_qspi_rst_n,
  input  logic                  i_qspi_clear,

  input  logic                  i_qspi_wr_en,
  input  logic [DATA_WIDTH-1:0] i_qspi_wr_data,
  output logic                  o_qspi_full,

  input  logic                  i_qspi_rd_en,
  output logic [DATA_WIDTH-1:0] o_qspi_rd_data,
  output logic                  o_qspi_empty,
  output logic                  o_qspi_valid
);

  localparam int PTR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

  logic [DATA_WIDTH-1:0] r_mem [0:DEPTH-1];
  logic [PTR_WIDTH-1:0]  r_wr_ptr;
  logic [PTR_WIDTH-1:0]  r_rd_ptr;
  logic [PTR_WIDTH:0]    r_count;

  assign o_qspi_full    = (r_count == DEPTH[PTR_WIDTH:0]);
  assign o_qspi_empty   = (r_count == '0);
  assign o_qspi_valid   = !o_qspi_empty;
  assign o_qspi_rd_data = o_qspi_empty ? '0 : r_mem[r_rd_ptr];

  always_ff @(posedge i_qspi_clk or negedge i_qspi_rst_n) begin
    if (!i_qspi_rst_n) begin
      r_wr_ptr  <= '0;
      r_rd_ptr  <= '0;
      r_count   <= '0;
    end else if (i_qspi_clear) begin
      r_wr_ptr  <= '0;
      r_rd_ptr  <= '0;
      r_count   <= '0;
    end else begin
      if (i_qspi_wr_en && !o_qspi_full) begin
        r_mem[r_wr_ptr] <= i_qspi_wr_data;
        r_wr_ptr        <= r_wr_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
      end

      if (i_qspi_rd_en && !o_qspi_empty) begin
        r_rd_ptr  <= r_rd_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
      end

      unique case ({i_qspi_wr_en && !o_qspi_full, i_qspi_rd_en && !o_qspi_empty})
        2'b10: r_count <= r_count + {{PTR_WIDTH{1'b0}}, 1'b1};
        2'b01: r_count <= r_count - {{PTR_WIDTH{1'b0}}, 1'b1};
        default: ;
      endcase
    end
  end

endmodule
