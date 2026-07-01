class axi_qspi_agent extends uvm_agent;
  `uvm_component_utils(axi_qspi_agent)

  axi_qspi_axi_sequencer sequencer;
  axi_qspi_axi_driver    driver;
  axi_qspi_axi_monitor   monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = axi_qspi_axi_sequencer::type_id::create("sequencer", this);
    driver    = axi_qspi_axi_driver::type_id::create("driver", this);
    monitor   = axi_qspi_axi_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
