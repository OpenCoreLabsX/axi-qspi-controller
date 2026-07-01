# AXI QSPI UVM Verification

This folder contains the UVM bring-up environment for the AXI QSPI controller.
The structure follows the AES IP project naming style.

## Tests

| Test | Purpose |
| --- | --- |
| `axi_qspi_reg_test` | Register reset/read/write smoke test and VERSION check |
| `axi_qspi_xip_test` | XIP base/mask/cmd/mode-byte configuration |
| `axi_qspi_fifo_irq_test` | TX FIFO write and transfer-done smoke flow |
| `axi_qspi_axi_skew_test` | AW/W independent handshake and WSTRB byte writes |
| `axi_qspi_all_test` | Directed regression wrapper |

## Run

```sh
make uvm_compile
make uvm_run UVM_TEST=axi_qspi_all_test
```

The current environment is a directed bring-up testbench. Add a QSPI flash
behavioral model before expanding into JEDEC command-level data checking.
