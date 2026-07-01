class axi_qspi_fifo_irq_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_fifo_irq_seq)

  function new(string name = "axi_qspi_fifo_irq_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;

    axi_write(AXI_QSPI_ADDR_IRQ_EN, 32'h0000_0003);
    axi_write(AXI_QSPI_ADDR_TXDATA, 32'h0000_00A5);
    axi_write(AXI_QSPI_ADDR_TXDATA, 32'h0000_005A);
    axi_read(AXI_QSPI_ADDR_STATUS, data);
    if (data[2] != 1'b0)
      `uvm_error("FIFO", $sformatf("TX empty should be low after writes, status=0x%08h", data))

    axi_write(AXI_QSPI_ADDR_CMD, {24'd0, QSPI_CMD_READ_SPI});
    axi_write(AXI_QSPI_ADDR_FLASH_ADDR, 32'h0000_0010);
    axi_write(AXI_QSPI_ADDR_LEN, 32'h0000_0001);
    axi_write(AXI_QSPI_ADDR_DUMMY, 32'h0000_0001);
    axi_write(AXI_QSPI_ADDR_CTRL, 32'h0000_0001);

    repeat (260) begin
      axi_read(AXI_QSPI_ADDR_STATUS, data);
      if (data[1]) break;
    end
    if (data[1] != 1'b1)
      `uvm_warning("IRQ", $sformatf("DONE bit not observed in smoke window, status=0x%08h", data))
  endtask
endclass
