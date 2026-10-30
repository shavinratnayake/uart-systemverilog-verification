# UART Controller Specification

## Clock and Reset

- Simulation clock period: 10 ns
- Active-low synchronous reset: rst_n

## UART Format

- Idle line: logic 1
- One start bit: logic 0
- Eight data bits
- Least significant bit transmitted first
- No parity in the first implementation
- One stop bit: logic 1

This format is commonly called 8-N-1.

## Simulation Timing

- Each UART bit lasts eight system-clock cycles.
- CLKS_PER_BIT = 8

## Transmitter Inputs

- clk
- rst_n
- tx_start
- tx_data[7:0]

## Transmitter Outputs

- tx_serial
- tx_busy
- tx_done

## Receiver Inputs

- clk
- rst_n
- rx_serial

## Receiver Outputs

- rx_data[7:0]
- rx_valid
- framing_error

## Future Features

- Even parity
- Odd parity
- Parity-error detection
- Randomized testing
- Functional coverage
- Assertions
- Python regression automation
- UVM verification environment