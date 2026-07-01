class axi_qspi_scoreboard extends uvm_component;
  `uvm_component_utils(axi_qspi_scoreboard)

  uvm_analysis_imp #(axi_qspi_axi_item, axi_qspi_scoreboard) item_export;
  int unsigned rsp_count;
  int unsigned err_count;
  int unsigned decerr_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction

  function void reset_mirror();
    rsp_count    = 0;
    err_count    = 0;
    decerr_count = 0;
  endfunction

  function void write(axi_qspi_axi_item tr);
    rsp_count++;
    case (tr.resp)
      2'b00: ; // OKAY — no action
      2'b10:   // SLVERR — expected for unsupported accesses, log only
        begin
          err_count++;
          `uvm_info("SB", $sformatf("SLVERR (expected for unsupported access) addr=0x%08h", tr.addr), UVM_MEDIUM)
        end
      2'b11:   // DECERR — unexpected, flag as error
        begin
          decerr_count++;
          `uvm_error("SB", $sformatf("DECERR unexpected addr=0x%08h resp=%0d", tr.addr, tr.resp))
        end
      default: // Reserved
        `uvm_error("SB", $sformatf("Reserved response code addr=0x%08h resp=%0d", tr.addr, tr.resp))
    endcase
  endfunction
endclass
