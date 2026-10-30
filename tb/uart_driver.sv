class uart_driver;

    // Mailbox
    mailbox #(uart_transaction) gen2drv;

    // Virtual interface
    virtual uart_if.DRIVER vif;

    function new(
        mailbox #(uart_transaction) gen2drv_in, 
        virtual uart_if.DRIVER vif_in
    );
        this.gen2drv = gen2drv_in;
        this.vif = vif_in;
    endfunction

    task reset();
        vif.drv_cb.rst_n    <= 1'b0;
        vif.drv_cb.tx_start <= 1'b0;
        vif.drv_cb.tx_data  <= '0;

        repeat (2) @(vif.drv_cb);

        vif.drv_cb.rst_n <= 1'b1;

        repeat (2) @(vif.drv_cb);
    endtask


    task run();
        uart_transaction trans;

        forever begin
            gen2drv.get(trans);

            while (vif.drv_cb.tx_busy) begin
                @(vif.drv_cb);
            end

            vif.drv_cb.tx_data  <= trans.data;
            vif.drv_cb.tx_start <= 1'b1;

            @(vif.drv_cb);

            vif.drv_cb.tx_start <= 1'b0;

            @(vif.drv_cb);

            while (vif.drv_cb.tx_busy) begin
                @(vif.drv_cb);
            end
        end  
    endtask

endclass
