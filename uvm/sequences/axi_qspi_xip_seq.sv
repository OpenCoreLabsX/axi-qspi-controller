class axi_qspi_xip_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_xip_seq)

  function new(string name = "axi_qspi_xip_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    axi_write(AXI_QSPI_ADDR_MODE, 32'h0000_0002);
    axi_write(AXI_QSPI_ADDR_DUMMY, 32'h0000_0008);
    axi_write(AXI_QSPI_ADDR_XIP_BASE, 32'h2000_0000);
    axi_write(AXI_QSPI_ADDR_XIP_MASK, 32'hFF00_0000);
    axi_write(AXI_QSPI_ADDR_XIP_CMD, 32'h0000_0000);
    axi_write(AXI_QSPI_ADDR_XIP_MODE, {23'd0, 1'b1, QSPI_CONT_READ_MODE});
    axi_write(AXI_QSPI_ADDR_XIP_CTRL, 32'h0000_0001);

    axi_read(AXI_QSPI_ADDR_XIP_MODE, data);
    if (data[8] != 1'b1 || data[7:0] != QSPI_CONT_READ_MODE)
      `uvm_error("XIP", $sformatf("XIP_MODE mismatch got=0x%08h", data))
  endtask
endclass
