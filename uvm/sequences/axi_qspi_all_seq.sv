class axi_qspi_all_seq extends axi_qspi_base_seq;
  `uvm_object_utils(axi_qspi_all_seq)

  function new(string name = "axi_qspi_all_seq");
    super.new(name);
  endfunction

  task body();
    axi_qspi_reg_smoke_seq reg_seq;
    axi_qspi_xip_seq       xip_seq;
    axi_qspi_axi_skew_seq  skew_seq;
    axi_qspi_fifo_irq_seq  fifo_seq;
    axi_qspi_slverr_seq    slverr_seq;

    reg_seq    = axi_qspi_reg_smoke_seq::type_id::create("reg_seq");
    xip_seq    = axi_qspi_xip_seq::type_id::create("xip_seq");
    skew_seq   = axi_qspi_axi_skew_seq::type_id::create("skew_seq");
    fifo_seq   = axi_qspi_fifo_irq_seq::type_id::create("fifo_seq");
    slverr_seq = axi_qspi_slverr_seq::type_id::create("slverr_seq");

    reg_seq.start(m_sequencer);
    xip_seq.start(m_sequencer);
    skew_seq.start(m_sequencer);
    fifo_seq.start(m_sequencer);
    slverr_seq.start(m_sequencer);
  endtask

endclass
