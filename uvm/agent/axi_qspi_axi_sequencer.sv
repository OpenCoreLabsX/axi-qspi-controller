class axi_qspi_axi_sequencer extends uvm_sequencer #(axi_qspi_axi_item);
  `uvm_component_utils(axi_qspi_axi_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
