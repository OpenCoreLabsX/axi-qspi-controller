class axi_qspi_slverr_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_slverr_seq)

  function new(string name = "axi_qspi_slverr_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] data;
    bit [31:0] saved_clkdiv;

    // Save current CLKDIV value (may have been modified by earlier sequences)
    axi_read(AXI_QSPI_ADDR_CLKDIV, saved_clkdiv);

    `uvm_info("SLVERR", "── Burst write (awlen=3) → SLVERR ──", UVM_LOW)
    axi_burst_write(AXI_QSPI_ADDR_CLKDIV, 32'hDEAD_BEEF, 8'd3);

    // Verify the register was NOT corrupted by the burst
    axi_read(AXI_QSPI_ADDR_CLKDIV, data);
    if (data != saved_clkdiv)
      `uvm_error("SLVERR", $sformatf("CLKDIV corrupted after burst write: exp=0x%08h got=0x%08h",
                                      saved_clkdiv, data))

    `uvm_info("SLVERR", "── Burst read (arlen=2) → SLVERR ──", UVM_LOW)
    axi_burst_read(AXI_QSPI_ADDR_CTRL, 8'd2, data);

    `uvm_info("SLVERR", "── Single-beat write to unmapped addr → SLVERR ──", UVM_LOW)
    axi_write_expect_err(32'h0000_00FC, 32'hCAFE_BABE);

    `uvm_info("SLVERR", "── Single-beat read from unmapped addr → SLVERR ──", UVM_LOW)
    axi_read_expect_err(32'h0000_00FC, data);
    if (data != 32'd0)
      `uvm_error("SLVERR", $sformatf("Unmapped read returned non-zero data: 0x%08h", data))

    // Confirm normal single-beat access still works after all error injections
    `uvm_info("SLVERR", "── Post-error sanity: normal write/read ──", UVM_LOW)
    axi_write(AXI_QSPI_ADDR_CLKDIV, 32'h0000_0005);
    axi_read(AXI_QSPI_ADDR_CLKDIV, data);
    if (data != 32'h0000_0005)
      `uvm_error("SLVERR", $sformatf("Normal access broken after errors: CLKDIV=0x%08h", data))

    `uvm_info("SLVERR", "All SLVERR tests passed", UVM_LOW)
  endtask
endclass
