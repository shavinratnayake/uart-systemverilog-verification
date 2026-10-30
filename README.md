# UART Transmitter Verification

SystemVerilog implementation and verification of an 8-bit UART transmitter.

I built a class-based verification environment to test the transmitter using constrained-random stimulus, a self-checking scoreboard, SystemVerilog Assertions (SVA), and functional coverage.

## Design

The UART transmitter supports:

- 8-bit data transmission
- Configurable clocks per bit
- Start and stop bit generation
- `tx_busy` status
- Single-cycle `tx_done` pulse
- FSM-based control

## Verification Environment

The testbench consists of a generator, driver, monitor, and scoreboard connected using mailboxes and a SystemVerilog interface.

```text
Generator ──► Driver ──► DUT ──► Monitor ──► Scoreboard
    │                                         ▲
    └──────────── Expected Data ──────────────┘
```

The generator produces constrained-random 8-bit data with additional weighting for `0x00`, `0xFF`, `0x55`, and `0xAA`.

The driver sends each transaction to the DUT through a clocking block. The monitor reconstructs each byte from the UART serial output and checks the start and stop bits. The scoreboard compares the reconstructed byte against the expected transaction.

## Assertions

SVA properties check:

- `tx_done` is a one-cycle pulse
- An accepted `tx_start` causes `tx_busy` to assert
- `tx_busy` remains asserted throughout a transmission
- `tx_busy` is low when `tx_done` is asserted
- `tx_busy` is cleared following reset
- `tx_done` is cleared following reset

## Coverage

Functional coverage includes the targeted data patterns `0x00`, `0xFF`, `0x55`, and `0xAA`, along with eight bins covering the full 8-bit data range.

Final regression results:

```text
Transactions : 1000
Passed       : 1000
Failed       : 0
RESULT       : PASS

Toggle coverage     : 97.8% (88/90)
Functional coverage : 100.0% (12/12)
```

## Project Structure

```text
├── docs/
│   ├── specification.md
│   └── verification_plan.md
├── rtl/
│   └── uart_tx.sv
└── tb/
    ├── uart_driver.sv
    ├── uart_generator.sv
    ├── uart_if.sv
    ├── uart_monitor.sv
    ├── uart_scoreboard.sv
    ├── uart_transaction.sv
    └── uart_tx_tb.sv
```

## Running with Verilator

Compile:

```bash
verilator --binary --coverage --assert -Wall -Wno-fatal \
  rtl/uart_tx.sv \
  tb/uart_if.sv \
  tb/uart_transaction.sv \
  tb/uart_generator.sv \
  tb/uart_driver.sv \
  tb/uart_monitor.sv \
  tb/uart_scoreboard.sv \
  tb/uart_tx_tb.sv \
  --top-module uart_tx_tb
```

Run the regression:

```bash
./obj_dir/Vuart_tx_tb
```

View the coverage summary:

```bash
verilator_coverage --report summary coverage.dat
```

## Tools

SystemVerilog, SVA, ModelSim/Questa, Verilator, Git, Linux/WSL
