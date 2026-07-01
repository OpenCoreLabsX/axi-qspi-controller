class axi_qspi_axi_driver extends uvm_driver #(axi_qspi_axi_item);
  `uvm_component_utils(axi_qspi_axi_driver)

  virtual axi_qspi_axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_qspi_axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Missing axi_qspi_axi_if for driver")
  endfunction

  task run_phase(uvm_phase phase);
    axi_qspi_axi_item tr;
    vif.init_master();
    wait (vif.aresetn == 1'b1);
    forever begin
      seq_item_port.get_next_item(tr);
      case (tr.cmd)
        AXI_QSPI_AXI_WRITE   : axi_write(tr);
        AXI_QSPI_AXI_READ    : axi_read(tr);
        AXI_QSPI_AXI_MEM_READ: axi_mem_read(tr);
        default              : `uvm_error("DRV", "Unsupported AXI command")
      endcase
      seq_item_port.item_done();
    end
  endtask

  task automatic axi_write(axi_qspi_axi_item tr);
    fork
      begin
        repeat (tr.aw_delay) @(posedge vif.aclk);
        vif.s_awaddr  <= tr.addr[7:0];
        vif.s_awlen   <= tr.burst_len;
        vif.s_awsize  <= 3'd2;
        vif.s_awburst <= 2'd1;
        vif.s_awvalid <= 1'b1;
        do @(posedge vif.aclk); while (!vif.s_awready);
        vif.s_awvalid <= 1'b0;
        vif.s_awaddr  <= '0;
      end
      begin
        repeat (tr.w_delay) @(posedge vif.aclk);
        for (int beat = 0; beat <= int'(tr.burst_len); beat++) begin
          vif.s_wdata  <= tr.data;
          vif.s_wstrb  <= tr.strb;
          vif.s_wlast  <= (beat == int'(tr.burst_len)) ? 1'b1 : 1'b0;
          vif.s_wvalid <= 1'b1;
          do @(posedge vif.aclk); while (!vif.s_wready);
        end
        vif.s_wvalid <= 1'b0;
        vif.s_wdata  <= '0;
        vif.s_wstrb  <= '0;
        vif.s_wlast  <= 1'b0;
      end
    join

    vif.s_bready <= 1'b1;
    do @(posedge vif.aclk); while (!vif.s_bvalid);
    tr.resp = vif.s_bresp;
    @(posedge vif.aclk);
    vif.s_bready <= 1'b0;

    if (tr.resp != tr.expected_resp)
      `uvm_error("AXI_WR", $sformatf("BRESP mismatch addr=0x%02h exp=%0d got=%0d",
                                       tr.addr[7:0], tr.expected_resp, tr.resp))
  endtask

  task automatic axi_read(axi_qspi_axi_item tr);
    @(posedge vif.aclk);
    vif.s_araddr  <= tr.addr[7:0];
    vif.s_arlen   <= tr.burst_len;
    vif.s_arsize  <= 3'd2;
    vif.s_arburst <= 2'd1;
    vif.s_arvalid <= 1'b1;
    do @(posedge vif.aclk); while (!vif.s_arready);
    vif.s_arvalid <= 1'b0;
    vif.s_araddr  <= '0;

    repeat (tr.r_ready_delay) @(posedge vif.aclk);
    vif.s_rready <= 1'b1;
    // Consume all R beats until rlast
    forever begin
      do @(posedge vif.aclk); while (!vif.s_rvalid);
      tr.data = vif.s_rdata;
      tr.resp = vif.s_rresp;
      if (vif.s_rlast) break;
    end
    @(posedge vif.aclk);
    vif.s_rready <= 1'b0;

    if (tr.resp != tr.expected_resp)
      `uvm_error("AXI_RD", $sformatf("RRESP mismatch addr=0x%02h exp=%0d got=%0d",
                                       tr.addr[7:0], tr.expected_resp, tr.resp))
  endtask

  task automatic axi_mem_read(axi_qspi_axi_item tr);
    @(posedge vif.aclk);
    vif.m_araddr  <= tr.addr;
    vif.m_arlen   <= tr.len;
    vif.m_arsize  <= 3'd2;
    vif.m_arburst <= 2'd1;
    vif.m_arvalid <= 1'b1;
    do @(posedge vif.aclk); while (!vif.m_arready);
    vif.m_arvalid <= 1'b0;
    vif.m_araddr  <= '0;

    vif.m_rready <= 1'b1;
    do @(posedge vif.aclk); while (!(vif.m_rvalid && vif.m_rlast));
    tr.data = vif.m_rdata;
    tr.resp = vif.m_rresp;
    @(posedge vif.aclk);
    vif.m_rready <= 1'b0;
  endtask
endclass
