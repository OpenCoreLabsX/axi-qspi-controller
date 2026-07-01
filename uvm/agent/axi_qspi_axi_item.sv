typedef enum int {
  AXI_QSPI_AXI_WRITE,
  AXI_QSPI_AXI_READ,
  AXI_QSPI_AXI_MEM_READ
} axi_qspi_axi_cmd_e;

class axi_qspi_axi_item extends uvm_sequence_item;
  `uvm_object_utils(axi_qspi_axi_item)

  rand axi_qspi_axi_cmd_e cmd;
  rand bit [31:0]         addr;
  rand bit [31:0]         data;
  rand bit [3:0]          strb;
  rand bit [7:0]          len;
  rand bit [7:0]          burst_len;
       bit [1:0]          expected_resp;
  rand int unsigned       aw_delay;
  rand int unsigned       w_delay;
  rand int unsigned       r_ready_delay;
       bit [1:0]          resp;

  constraint c_default {
    strb inside {[4'h1:4'hF]};
    aw_delay <= 8;
    w_delay <= 8;
    r_ready_delay <= 8;
    burst_len == 0;
  }

  function new(string name = "axi_qspi_axi_item");
    super.new(name);
    strb          = 4'hF;
    len           = 8'd0;
    burst_len     = 8'd0;
    expected_resp = 2'b00;
  endfunction
endclass
