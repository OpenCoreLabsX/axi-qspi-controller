class axi_qspi_axi_skew_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_axi_skew_seq)

  function new(string name = "axi_qspi_axi_skew_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    axi_write(AXI_QSPI_ADDR_CLKDIV, 32'h0000_000B, 4'hF, 0, 5);
    axi_read(AXI_QSPI_ADDR_CLKDIV, data);
    if (data != 32'h0000_000B)
      `uvm_error("SKEW", $sformatf("W channel delay write failed got=0x%08h", data))

    axi_write(AXI_QSPI_ADDR_DUMMY, 32'h0000_000C, 4'hF, 6, 0);
    axi_read(AXI_QSPI_ADDR_DUMMY, data);
    if (data != 32'h0000_000C)
      `uvm_error("SKEW", $sformatf("AW channel delay write failed got=0x%08h", data))

    axi_write(AXI_QSPI_ADDR_DUMMY, 32'h0000_00AA, 4'h1);
    axi_read(AXI_QSPI_ADDR_DUMMY, data);
    if (data[7:0] != 8'hAA)
      `uvm_error("SKEW", $sformatf("WSTRB byte write failed got=0x%08h", data))
  endtask
endclass
