<div align="center">

<img src="https://raw.githubusercontent.com/OpenCoreLabsX/apb-usart-core/36a802fc11f9a65acace85c78b591b82f889031f/banner.png" alt="OpenCoreLabsX Banner" width="100%">

# GitHub Readme Stats

Get dynamically generated GitHub stats on your READMEs!

<p>
  <img src="https://img.shields.io/badge/Test-failing-red?style=flat&logo=github" alt="Test">
  <img src="https://img.shields.io/badge/contributors-302-brightgreen?style=flat" alt="Contributors">
  <img src="https://img.shields.io/badge/codecov-97%25-brightgreen?style=flat&logo=codecov" alt="Codecov">
  <img src="https://img.shields.io/badge/issues-167%20open-blue?style=flat" alt="Issues">
  <img src="https://img.shields.io/badge/pull%20requests-119%20open-blue?style=flat" alt="Pull Requests">
  <img src="https://img.shields.io/badge/openssf%20scorecard-6.5-yellow?style=flat" alt="OpenSSF Scorecard">
</p>

[![Powered by Vercel](https://img.shields.io/badge/Powered%20by-Vercel-black?style=for-the-badge&logo=vercel)](https://vercel.com)

</div>

---

# AXI QSPI Controller IP Core

AXI QSPI controller RTL written in SystemVerilog for MCU, SoC, and RISC-V based systems.

## Features

| Item | Description |
| --- | --- |
| Control interface | AXI4-Full register interface |
| Memory interface | AXI4 memory-mapped read interface |
| XIP | Execute-in-place read window with base/mask decode |
| XIP fast path | Quad I/O read command and continuous-read mode byte support |
| Flash modes | Standard SPI, Dual SPI, Quad SPI |
| Clocking | Configurable SPI clock divider |
| Commands | Read, program, erase, write-enable, status/config, and JEDEC ID command constants |
| Data path | TX/RX FIFO for command data transfer |
| Interrupts | Transfer done and error events |
| Status flags | Busy, done, error, TX empty, RX valid |

## XIP Registers

| Address | Name | Description |
| --- | --- | --- |
| `0x34` | `XIP_CTRL` | Bit 0 enables memory-mapped XIP reads |
| `0x38` | `XIP_BASE` | AXI memory window base address |
| `0x3C` | `XIP_MASK` | AXI address mask used for XIP hit decode |
| `0x40` | `XIP_CMD` | Optional read command override, 0 selects mode default |
| `0x44` | `XIP_MODE` | Bit 8 enables continuous-read mode byte, bits 7:0 hold the mode byte, default `0xA0` |

When XIP is enabled in Quad mode and `XIP_CMD` is zero, the memory interface selects
Quad I/O read command `0xEB` when `XIP_MODE[8]` is set. Clearing `XIP_MODE[8]`
selects the simpler Quad Output read command `0x6B`.

## Repository Structure

```text
.
|-- inc/        Global defines
|-- rtl/        Synthesizable AXI QSPI RTL
|-- filelist.f  RTL compile filelist
`-- Makefile    Verilator lint target
```

## Build

```sh
make lint
```
