# UART Transmitter — SystemVerilog Verification

## Overview

This project implements an 8-bit UART transmitter in SystemVerilog, along with a class-based verification environment to test its functionality.

The testbench uses constrained-random stimulus, a self-checking scoreboard, SystemVerilog Assertions (SVA), and functional coverage to verify the transmitter's behavior.

## Design

The UART transmitter uses a four-state finite state machine (FSM):

- `IDLE` — Waits for a transmission request
- `START_BIT` — Transmits the start bit
- `DATA_BITS` — Transmits 8 data bits, LSB first
- `STOP_BIT` — Transmits the stop bit

The transmitter uses the standard 8N1 format (8 data bits, no parity, 1 stop bit).

The `CLKS_PER_BIT` parameter controls the baud timing and is set to 8 for simulation.

**Main signals:**

- `tx_start` — Starts a transmission when the transmitter is idle
- `tx_data` — 8-bit input data
- `tx_serial` — Serial output
- `tx_busy` — Indicates an active transmission
- `tx_done` — One-clock pulse indicating completion
- `rst_n` — Active-low synchronous reset

## Verification Architecture

The verification environment is built using class-based SystemVerilog. It uses separate components for stimulus generation, driving DUT inputs, monitoring serial output, and checking results.

The main components are:

- **Transaction (`uart_transaction.sv`):** Defines the 8-bit randomized data field and weighted distribution constraints.
- **Generator (`uart_generator.sv`):** Generates constrained-random transactions and sends them to the driver and scoreboard.
- **Driver (`uart_driver.sv`):** Receives transactions and drives `tx_data` and `tx_start` through the interface. It also monitors `tx_busy` before starting the next transmission.
- **Monitor (`uart_monitor.sv`):** Samples the UART serial output, checks the start and stop bits, reconstructs the transmitted byte, and collects functional coverage.
- **Scoreboard (`uart_scoreboard.sv`):** Compares the reconstructed data against the expected data and tracks passing and failing transactions.
- **Interface (`uart_if.sv`):** Connects the testbench to the DUT using separate driver and monitor clocking blocks and modports.
- **Top-Level Testbench (`uart_tx_tb.sv`):** Instantiates the DUT, initializes the verification components, manages reset and simulation execution, and implements six SystemVerilog Assertions.

Typed mailboxes are used to pass transactions between the generator, driver, monitor, and scoreboard. The environment runs 1,000 constrained-random transactions and uses automated checking to verify the transmitted data.

### Test Stimulus

The generator uses constrained-random transactions with weighted distributions to increase the occurrence of specific data patterns:

- `0x00` — All zeros
- `0xFF` — All ones
- `0x55` — Alternating bits
- `0xAA` — Alternating bits

The remaining 8-bit values are also included in the randomization space.

The testbench generates 1,000 transactions per simulation.

## SystemVerilog Assertions

Six assertions are implemented in the top-level testbench to check:

1. `tx_done` remains asserted for only one clock cycle
2. An accepted transmission request causes `tx_busy` to assert
3. Reset clears `tx_busy`
4. `tx_busy` remains asserted until transmission completion
5. `tx_busy` is low when `tx_done` is asserted
6. Reset clears `tx_done`

These assertions provide additional checks alongside the monitor and scoreboard.

## Functional Coverage

Functional coverage is collected in the UART monitor after each decoded frame.

The covergroup contains 12 bins:

- 4 bins for specific data patterns (`0x00`, `0xFF`, `0x55`, `0xAA`)
- 8 bins covering ranges across the 8-bit data space

Coverage is based on the bytes reconstructed from the serial output.

## Verification Results

The simulation was run using Verilator 5.051 (development build) with 1,000 constrained-random transactions.

| Metric | Result |
|---|---|
| Transactions | 1,000 |
| Passed | 1,000 |
| Failed | 0 |
| Functional coverage | 100% (12/12 bins) |
| Toggle coverage | 97.8% |
| Line coverage | 51.3% |
| Branch coverage | 54.2% |
| Expression coverage | 30.8% |
| Simulation result | PASS |

All 1,000 scoreboard comparisons passed, with no reported data mismatches.

Functional coverage reached 100% across the defined covergroup bins. This does not indicate that every possible 8-bit value was individually tested.

## Implementation Notes

- The UART transmitter uses a synchronous active-low reset.
- The driver uses a clocking block to apply stimulus and monitor transmitter status.
- The monitor samples the serial output near the midpoint of each UART bit.
- The scoreboard uses four-state equality to compare expected and received data.
- Invalid start and stop bits cause a fatal simulation error.
- Transaction randomization failures terminate the simulation.
- A simulation timeout is included to prevent indefinite execution if verification stalls.
- The testbench is class-based SystemVerilog and does not use UVM.

## Project Structure

```text
uart-verification-project/
├── rtl/
│   └── uart_tx.sv
├── tb/
│   ├── uart_if.sv
│   ├── uart_transaction.sv
│   ├── uart_generator.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_scoreboard.sv
│   └── uart_tx_tb.sv
└── README.md
```

## Running the Simulation

The project can be compiled and run using Verilator.

**Compile:**

```bash
verilator --binary --coverage --assert -Wall -Wno-fatal \
  tb/uart_if.sv \
  tb/uart_transaction.sv \
  tb/uart_generator.sv \
  tb/uart_driver.sv \
  tb/uart_monitor.sv \
  tb/uart_scoreboard.sv \
  rtl/uart_tx.sv \
  tb/uart_tx_tb.sv \
  --top-module uart_tx_tb
```

**Run:**

```bash
./obj_dir/Vuart_tx_tb
```

**Coverage summary:**

```bash
verilator_coverage --report summary coverage.dat
```

## Tools

- SystemVerilog
- Verilator 
- Questa/ModelSim
- Git/GitHub


