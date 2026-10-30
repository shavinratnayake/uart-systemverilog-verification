class uart_generator;

    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) gen2scb;
    int num_transactions;

    function new(
        mailbox #(uart_transaction) gen2drv_in,
        mailbox #(uart_transaction) gen2scb_in, 
        int num_transactions_in
    );
        this.gen2drv = gen2drv_in;
        this.gen2scb = gen2scb_in;
        this.num_transactions = num_transactions_in;
    endfunction

    task run();
        uart_transaction trans;
        uart_transaction expected_trans;

        repeat (num_transactions) begin
            trans = new();
            expected_trans = new();

            if (trans.randomize() == 0) begin
                $error("UART transaction randomization failed");
            end

            expected_trans.data = trans.data;

            gen2drv.put(trans);
            gen2scb.put(expected_trans);
        end
    endtask

endclass

