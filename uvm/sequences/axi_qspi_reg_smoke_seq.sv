class axi_qspi_reg_smoke_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_reg_smoke_seq)

  function new(string name = "axi_qspi_reg_smoke_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    axi_read(AXI_QSPI_ADDR_VERSION, data);
    if (data != `AXI_QSPI_VERSION)
      `uvm_error("REG", $sformatf("VERSION mismatch exp=0x%08h got=0x%08h", `AXI_QSPI_VERSION, data))

    axi_write(AXI_QSPI_ADDR_CLKDIV, 32'h0000_0007);
    axi_read(AXI_QSPI_ADDR_CLKDIV, data);
    if (data != 32'h0000_0007)
      `uvm_error("REG", $sformatf("CLKDIV mismatch got=0x%08h", data))

    axi_write(AXI_QSPI_ADDR_MODE, 32'h0000_0002);
    axi_read(AXI_QSPI_ADDR_MODE, data);
    if (data[1:0] != QSPI_MODE_QUAD)
      `uvm_error("REG", $sformatf("MODE mismatch got=0x%08h", data))

    axi_write(AXI_QSPI_ADDR_CMD, {24'd0, QSPI_CMD_READ_ID});
    axi_read(AXI_QSPI_ADDR_CMD, data);
    if (data[7:0] != QSPI_CMD_READ_ID)
      `uvm_error("REG", $sformatf("CMD mismatch got=0x%08h", data))
  endtask
endclass
