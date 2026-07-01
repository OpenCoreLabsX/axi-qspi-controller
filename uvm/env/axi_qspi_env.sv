class axi_qspi_env extends uvm_env;
  `uvm_component_utils(axi_qspi_env)

  axi_qspi_agent      agent;
  axi_qspi_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = axi_qspi_agent::type_id::create("agent", this);
    sb    = axi_qspi_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(sb.item_export);
  endfunction
endclass
