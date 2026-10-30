class uart_scoreboard;

    mailbox #(uart_transaction) mon2scb;
    mailbox #(uart_transaction) gen2scb;

    int num_transactions;
    int passed;
    int failed;

    function new(
        mailbox #(uart_transaction) gen2scb_in,
        mailbox #(uart_transaction) mon2scb_in,
        int num_transactions_in
    );
        this.mon2scb          = mon2scb_in;
        this.gen2scb          = gen2scb_in;
        this.num_transactions = num_transactions_in;
        this.passed           = 0;
        this.failed           = 0;
    endfunction

    task run();
        uart_transaction expected_trans;
        uart_transaction actual_trans;
        
        repeat (num_transactions) begin
            gen2scb.get(expected_trans);
            mon2scb.get(actual_trans);

            if (actual_trans.data === expected_trans.data) begin
                passed ++;
            end
            else begin
                $error(
                    "UART scoreboard mismatch: Expected = 0x%02h, Actual = 0x%02h",
                    expected_trans.data,
                    actual_trans.data
                );
                failed ++;
            end
        end
    endtask


    
    function void report();
        $display("========================================");
        $display("UART VERIFICATION TEST SUMMARY");
        $display("Transactions : %0d", num_transactions);
        $display("Passed       : %0d", passed);
        $display("Failed       : %0d", failed);

        if (failed == 0)
            $display("RESULT       : PASS");
        else
            $display("RESULT       : FAIL");

        $display("========================================");
    endfunction

endclass
