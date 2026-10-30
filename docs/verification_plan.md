# UART Transmitter Verification Plan

## 1. Overview

This document defines the verification plan for an 8-bit UART transmitter implemented in SystemVerilog. The purpose of verification is to confirm that the UART transmitter operates correctly during normal transmission, boundary conditions, busy-state requests, and reset conditions.

The verification environment uses directed testing, randomized stimulus, self-checking tasks, SystemVerilog Assertions (SVA), functional coverage, and code coverage to verify the design.\


## 2. DUT Interface

The UART transmitter communicates with the testbench through the following input and output signals:

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| clk | Input | 1 bit | System clock used to synchronize UART transmitter operation |
| rst_n | Input | 1 bit | Active-low reset |
| tx_start | Input | 1 bit | Starts a new UART transmission when asserted while the transmitter is idle |
| tx_data | Input | 8 bits | Parallel data byte to be transmitted |
| tx_serial | Output | 1 bit | Serial UART transmit data output |
| tx_busy | Output | 1 bit | Indicates that a UART transmission is currently in progress |
| tx_done | Output | 1 bit | Pulses when a UART transmission has completed |


## 3. Verification Requirements

The following requirements define the expected behavior of the UART transmitter and the corresponding verification method.

| ID | Requirement | Verification Method | Checker / Assertion | Coverage |
|----|-------------|---------------------|---------------------|----------|
| UART-01 | A valid `tx_start` request while the transmitter is idle shall begin a transmission. | Directed and randomized transmission tests | `check_start_causes_busy` | `idle_request` |
| UART-02 | The transmitted UART frame shall contain one start bit, eight data bits transmitted LSB-first, and one stop bit. | Directed and randomized byte transmissions | `check_uart_frame()` | Data pattern and data range bins |
| UART-03 | `tx_busy` shall remain HIGH for the duration of an active transmission. | Normal transmission and stress testing | `check_tx_busy_until_done` | Exercised during all transmissions |
| UART-04 | `tx_done` shall assert for only one clock cycle when transmission completes. | Normal transmission tests | `check_tx_done_a` | Exercised during all completed transmissions |
| UART-05 | `tx_done` and `tx_busy` shall not be HIGH simultaneously. | Normal transmission tests | `check_tx_done_and_tx_busy` | Exercised at transmission completion |
| UART-06 | A new `tx_start` request while `tx_busy` is HIGH shall not corrupt the current transmission. | Busy-request stress test using `send_bad_data()` | `check_busy_request_ignored` and `check_uart_frame()` | `busy_request` |
| UART-07 | Reset while the transmitter is idle shall return the transmitter outputs to their reset state. | Explicit reset-while-idle test | Reset assertions | `reset_while_idle` |
| UART-08 | Reset during an active transmission shall abort/reset transmitter operation correctly. | Reset-while-busy stress test | Reset assertions | `reset_while_busy` |


## 4. Test Strategy

The UART transmitter is verified using a combination of directed testing, randomized testing, stress testing, self-checking tasks, SystemVerilog Assertions (SVA), functional coverage, and code coverage.

### 4.1 Directed Testing

Directed tests are used to verify known data patterns and important boundary values. The following test vectors are transmitted:

- `8'h00` - All zeros
- `8'hFF` - All ones
- `8'h55` - Alternating `01010101` pattern
- `8'hAA` - Alternating `10101010` pattern
- `8'h25`
- `8'h70`
- `8'h90`
- `8'hD0`

Each transmitted byte is automatically checked to verify the start bit, eight LSB-first data bits, and stop bit.

### 4.2 Randomized Testing

Randomized 8-bit data values are generated using `$urandom_range(0,255)` to exercise additional input combinations beyond the directed test vectors.

The same self-checking UART frame checker used for directed testing verifies the randomly generated transmissions.

### 4.3 Busy-Request Stress Testing

A stress test asserts a second `tx_start` request while an existing transmission is in progress and `tx_busy` is HIGH.

The test verifies that the additional request does not corrupt the active UART frame and that the original transmission completes correctly.

### 4.4 Reset Testing

Reset behavior is tested under two operating conditions:

1. Reset while the transmitter is idle.
2. Reset while a transmission is active.

These tests verify that the transmitter returns to its expected reset state under both conditions.

### 4.5 Self-Checking

Self-checking testbench tasks automatically verify UART behavior during simulation. These checks include UART frame contents, `tx_busy` behavior, and `tx_done` behavior.

Automatic checking reduces reliance on manual waveform inspection and allows failures to be detected during simulation.

### 4.6 SystemVerilog Assertions

SystemVerilog Assertions continuously monitor important UART protocol and control requirements throughout simulation.

Assertions are used to verify behaviors including:

- A valid transmission request causes `tx_busy` to assert.
- `tx_busy` remains asserted during an active transmission.
- `tx_done` is limited to a single clock cycle.
- `tx_done` and `tx_busy` are not asserted simultaneously.
- Requests received while the transmitter is busy do not disrupt the active transmission.
- Reset correctly clears transmitter control outputs.

### 4.7 Coverage

Functional coverage is used to confirm that planned verification scenarios have been exercised, including special data patterns, the complete 8-bit data range, requests while idle and busy, and reset while idle and busy.

Verilator code coverage is also collected to measure line, branch, expression, and toggle coverage of the design.


## 5. Functional Coverage Plan

Functional coverage is used to confirm that the planned UART verification scenarios have been exercised during simulation.

### 5.1 Data Coverage

Data coverage verifies that important data patterns and the complete 8-bit input range are exercised.

Special data patterns include:

- `8'h00` - All zeros
- `8'hFF` - All ones
- `8'h55` - Alternating `01010101` pattern
- `8'hAA` - Alternating `10101010` pattern

The complete 8-bit data space is also divided into eight coverage ranges:

- `8'h00` to `8'h1F`
- `8'h20` to `8'h3F`
- `8'h40` to `8'h5F`
- `8'h60` to `8'h7F`
- `8'h80` to `8'h9F`
- `8'hA0` to `8'hBF`
- `8'hC0` to `8'hDF`
- `8'hE0` to `8'hFF`

### 5.2 Request Coverage

Request coverage verifies that transmission requests are exercised while the transmitter is both idle and busy.

The following scenarios are covered:

- `idle_request` - `tx_start` is asserted while `tx_busy` is LOW.
- `busy_request` - `tx_start` is asserted while `tx_busy` is HIGH.

### 5.3 Reset Coverage

Reset coverage verifies that reset is exercised while the transmitter is in different operating states.

The following scenarios are covered:

- `reset_while_idle` - Reset is asserted while `tx_busy` is LOW.
- `reset_while_busy` - Reset is asserted while `tx_busy` is HIGH.

### 5.4 Coverage Goal

The functional coverage goal for the UART transmitter is 100% of the defined coverage bins.

The functional coverage model contains 16 bins:

- 4 special-pattern bins
- 8 data-range bins
- 2 request-state bins
- 2 reset-state bins

A coverage bin is considered covered once the corresponding verification scenario has been exercised during simulation.

## 6. SystemVerilog Assertions

SystemVerilog Assertions (SVA) are used to continuously monitor important UART control and timing requirements during simulation. If a requirement is violated, the corresponding assertion automatically reports a failure.

Normal-operation assertions are disabled during reset using `disable iff (!rst_n)` where appropriate.

### 6.1 Transmission Start

When `tx_start` is asserted while the transmitter is idle, `tx_busy` must be HIGH on the following sampled clock.

`(tx_start && !tx_busy) |=> tx_busy`

### 6.2 TX Done Pulse Width

When `tx_done` is HIGH, it must return LOW on the following sampled clock. This verifies that `tx_done` does not remain asserted for multiple clock cycles.

`tx_done |=> !tx_done`

### 6.3 Busy Until Transmission Completion

Once `tx_busy` rises, it must remain HIGH during the transmission until `tx_done` occurs.

`$rose(tx_busy) |=> tx_busy until tx_done`

### 6.4 TX Done and TX Busy Relationship

Whenever `tx_done` is HIGH, `tx_busy` must be LOW on the same sampled clock.

`tx_done |-> !tx_busy`

### 6.5 Request While Busy

If `tx_start` is asserted while the transmitter is already busy, `tx_busy` must remain HIGH on the following sampled clock.

`(tx_start && tx_busy) |=> tx_busy`

### 6.6 Reset Behavior

Reset assertions verify that transmitter control outputs return to their expected reset values.

When reset is active, `tx_busy` must be LOW on the following sampled clock:

`!rst_n |=> !tx_busy`

When reset is active, `tx_done` must be LOW on the following sampled clock:

`!rst_n |=> !tx_done`

## 7. Verification Results

The final UART transmitter regression completed successfully with all tests passing and no assertion failures.

### 7.1 Test Results

The final regression executed nine UART frame tests.

- Tests passed: 9
- Tests failed: 0
- Overall result: PASS

The tested frames included directed data patterns, additional data-range values, and randomized stimulus. Busy-request and reset stress scenarios were also exercised during the regression.

### 7.2 Functional Coverage Results

The functional coverage goal was achieved.

- Covergroup coverage: 100%
- Covered bins: 16 / 16

All defined special-pattern, data-range, request-state, and reset-state coverage bins were exercised.

### 7.3 Code Coverage Results

Verilator code coverage produced the following results:

| Coverage Type | Result | Covered / Total |
|---------------|--------|-----------------|
| Line | 53.1% | 34 / 64 |
| Toggle | 51.9% | 109 / 210 |
| Branch | 70.0% | 14 / 20 |
| Expression | 46.2% | 6 / 13 |
| FSM State | N/A | 0 / 0 |
| FSM Arc | N/A | 0 / 0 |
| Covergroup | 100.0% | 16 / 16 |

FSM state and FSM arc coverage contain no coverage points in the generated report and are therefore treated as not applicable rather than as failed coverage.

### 7.4 Verification Summary

The final regression passed all self-checking tests and completed without assertion failures. Functional coverage reached 100% of the defined coverage model.

Code coverage indicates that additional RTL paths and signal transitions remain uncovered. These coverage holes should be reviewed to determine whether they represent meaningful untested behavior, unreachable or defensive code, or scenarios that require additional stimulus.