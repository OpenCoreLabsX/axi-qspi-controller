class axi_qspi_xip_test extends axi_qspi_base_test;
  `uvm_component_utils(axi_qspi_xip_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_qspi_xip_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = axi_qspi_xip_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
