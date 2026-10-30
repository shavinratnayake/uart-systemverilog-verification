`timescale 1ns/1ps

module uart_tx_tb;

    localparam int CLOCK_PERIOD     = 10;
    localparam int CLKS_PER_BIT     = 8;
    localparam int NUM_TRANSACTIONS = 1000;

    logic clk;

    // UART interface
    uart_if uart_interface(clk);

    // Mailboxes
    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) gen2scb;
    mailbox #(uart_transaction) mon2scb;

    // Verification components
    uart_generator generator;
    uart_driver driver;
    uart_monitor #(CLKS_PER_BIT) monitor;
    uart_scoreboard scoreboard;


    // DUT
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk       (clk),
        .rst_n     (uart_interface.rst_n),
        .tx_start  (uart_interface.tx_start),
        .tx_data   (uart_interface.tx_data),
        .tx_serial (uart_interface.tx_serial),
        .tx_busy   (uart_interface.tx_busy),
        .tx_done   (uart_interface.tx_done)
    );


    // Clock generation
    initial begin
        clk = 1'b0;

        forever begin
            #(CLOCK_PERIOD / 2);
            clk = ~clk;
        end
    end


    // ============================================================
    // Assertions
    // ============================================================

    // tx_done must only remain high for one clock cycle.
    property p_tx_done_one_cycle;
        @(posedge clk)
        disable iff (!uart_interface.rst_n)
            uart_interface.tx_done |=> !uart_interface.tx_done;
    endproperty

    ap_tx_done_one_cycle:
        assert property (p_tx_done_one_cycle)
        else $error("ASSERTION FAILED: tx_done remained HIGH for more than one clock cycle");


    // An accepted transmission request must cause tx_busy to assert.
    property p_accepted_start_causes_busy;
        @(posedge clk)
        disable iff (!uart_interface.rst_n)
            (uart_interface.tx_start && !uart_interface.tx_busy) |=> uart_interface.tx_busy;
    endproperty

    ap_accepted_start_causes_busy:
        assert property (p_accepted_start_causes_busy)
        else $error("ASSERTION FAILED: tx_busy did not assert after tx_start");


    // tx_busy must be low following reset.
    property p_reset_clears_busy;
        @(posedge clk)
            !uart_interface.rst_n |=> !uart_interface.tx_busy;
    endproperty

    ap_reset_clears_busy:
        assert property (p_reset_clears_busy)
        else $error("ASSERTION FAILED: tx_busy was HIGH following reset");


    // tx_busy must remain asserted throughout a transmission.
    property p_busy_until_done;
        @(posedge clk)
        disable iff (!uart_interface.rst_n)
            $rose(uart_interface.tx_busy) |=> uart_interface.tx_busy until uart_interface.tx_done;
    endproperty

    ap_busy_until_done:
        assert property (p_busy_until_done)
        else $error("ASSERTION FAILED: tx_busy dropped before tx_done");


    // tx_busy must be low when tx_done is asserted.
    property p_done_implies_not_busy;
        @(posedge clk)
        disable iff (!uart_interface.rst_n)
            uart_interface.tx_done |-> !uart_interface.tx_busy;
    endproperty

    ap_done_implies_not_busy:
        assert property (p_done_implies_not_busy)
        else $error("ASSERTION FAILED: tx_busy was HIGH while tx_done was HIGH");


    // tx_done must remain low following reset.
    property p_reset_clears_done;
        @(posedge clk)
            !uart_interface.rst_n |=> !uart_interface.tx_done;
    endproperty

    ap_reset_clears_done:
        assert property (p_reset_clears_done)
        else $error("ASSERTION FAILED: tx_done was HIGH following reset");


    // ============================================================
    // Test
    // ============================================================

    initial begin

        // Create communication channels.
        gen2drv = new();
        gen2scb = new();
        mon2scb = new();

        // Create verification components.
        generator  = new(gen2drv, gen2scb, NUM_TRANSACTIONS);
        driver     = new(gen2drv, uart_interface);
        monitor    = new(uart_interface, mon2scb);
        scoreboard = new(gen2scb, mon2scb, NUM_TRANSACTIONS);

        // Reset DUT.
        driver.reset();

        // Generate constrained-random transactions.
        generator.run();

        // Run persistent verification components.
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_any

        // Scoreboard finishes after all expected transactions
        // have been checked. Stop persistent workers.
        disable fork;

        // Allow the DUT to finish its final tx_done pulse.
        repeat (2) @(posedge clk);

        scoreboard.report();

        $finish;
    end

endmodule
