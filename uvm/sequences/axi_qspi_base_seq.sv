class axi_qspi_base_seq extends uvm_sequence #(axi_qspi_axi_item);
  `uvm_object_utils(axi_qspi_base_seq)

  function new(string name = "axi_qspi_base_seq");
    super.new(name);
  endfunction

  task automatic axi_write(bit [31:0] addr, bit [31:0] data, bit [3:0] strb = 4'hF,
                           int unsigned aw_delay = 0, int unsigned w_delay = 0);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("wr");
    tr.cmd           = AXI_QSPI_AXI_WRITE;
    tr.addr          = addr;
    tr.data          = data;
    tr.strb          = strb;
    tr.aw_delay      = aw_delay;
    tr.w_delay       = w_delay;
    tr.burst_len     = 8'd0;
    tr.expected_resp = 2'b00;
    start_item(tr);
    finish_item(tr);
  endtask

  task automatic axi_read(bit [31:0] addr, output bit [31:0] data);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("rd");
    tr.cmd           = AXI_QSPI_AXI_READ;
    tr.addr          = addr;
    tr.burst_len     = 8'd0;
    tr.expected_resp = 2'b00;
    start_item(tr);
    finish_item(tr);
    data = tr.data;
  endtask

  // Issue a burst write (burst_len+1 beats) and expect SLVERR.
  task automatic axi_burst_write(bit [31:0] addr, bit [31:0] data,
                                 bit [7:0] burst_len, bit [1:0] exp_resp = 2'b10);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("burst_wr");
    tr.cmd           = AXI_QSPI_AXI_WRITE;
    tr.addr          = addr;
    tr.data          = data;
    tr.strb          = 4'hF;
    tr.burst_len     = burst_len;
    tr.expected_resp = exp_resp;
    start_item(tr);
    finish_item(tr);
  endtask

  // Issue a burst read (burst_len+1 beats) and expect SLVERR.
  task automatic axi_burst_read(bit [31:0] addr, bit [7:0] burst_len,
                                output bit [31:0] data, input bit [1:0] exp_resp = 2'b10);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("burst_rd");
    tr.cmd           = AXI_QSPI_AXI_READ;
    tr.addr          = addr;
    tr.burst_len     = burst_len;
    tr.expected_resp = exp_resp;
    start_item(tr);
    finish_item(tr);
    data = tr.data;
  endtask

  // Issue a single-beat write to an invalid address and expect SLVERR.
  task automatic axi_write_expect_err(bit [31:0] addr, bit [31:0] data,
                                      bit [1:0] exp_resp = 2'b10);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("wr_err");
    tr.cmd           = AXI_QSPI_AXI_WRITE;
    tr.addr          = addr;
    tr.data          = data;
    tr.strb          = 4'hF;
    tr.burst_len     = 8'd0;
    tr.expected_resp = exp_resp;
    start_item(tr);
    finish_item(tr);
  endtask

  // Issue a single-beat read to an invalid address and expect SLVERR.
  task automatic axi_read_expect_err(bit [31:0] addr, output bit [31:0] data,
                                     input bit [1:0] exp_resp = 2'b10);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("rd_err");
    tr.cmd           = AXI_QSPI_AXI_READ;
    tr.addr          = addr;
    tr.burst_len     = 8'd0;
    tr.expected_resp = exp_resp;
    start_item(tr);
    finish_item(tr);
    data = tr.data;
  endtask

  task automatic axi_mem_read(bit [31:0] addr, bit [7:0] len, output bit [31:0] data);
    axi_qspi_axi_item tr;
    tr = axi_qspi_axi_item::type_id::create("mem_rd");
    tr.cmd  = AXI_QSPI_AXI_MEM_READ;
    tr.addr = addr;
    tr.len  = len;
    start_item(tr);
    finish_item(tr);
    data = tr.data;
  endtask
endclass
