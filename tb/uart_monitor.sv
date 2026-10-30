class uart_monitor #(
    parameter int CLKS_PER_BIT = 8
);

    virtual uart_if.MONITOR vif;
    mailbox #(uart_transaction) mon2scb;

    logic [7:0] received_data;

    covergroup uart_cg;
        data_cp: coverpoint received_data {

            bins all_zeros = {8'h00};
            bins all_ones = {8'hFF};
            bins alt_55 = {8'h55};
            bins alt_AA = {8'hAA};

            bins range_00_1F = {[8'h00:8'h1F]};
            bins range_20_3F = {[8'h20:8'h3F]};
            bins range_40_5F = {[8'h40:8'h5F]};
            bins range_60_7F = {[8'h60:8'h7F]};
            bins range_80_9F = {[8'h80:8'h9F]};
            bins range_A0_BF = {[8'hA0:8'hBF]};
            bins range_C0_DF = {[8'hC0:8'hDF]};
            bins range_E0_FF = {[8'hE0:8'hFF]};
        }
    endgroup

    function new(
        virtual uart_if.MONITOR vif_in,
        mailbox #(uart_transaction) mon2scb_in
    );
        this.vif = vif_in;
        this.mon2scb = mon2scb_in;

        uart_cg = new();
    endfunction

    task run();
        uart_transaction trans;
    
        forever begin
            while(vif.mon_cb.tx_serial == 1'b1) begin
                @(vif.mon_cb);
            end

            repeat (CLKS_PER_BIT / 2) @(vif.mon_cb);

            if (vif.mon_cb.tx_serial != 1'b0) begin
                $error("UART montior error: invalid start bit");
            end

            for (int i = 0; i < 8; i ++) begin
                repeat (CLKS_PER_BIT) @(vif.mon_cb);
                received_data[i] = vif.mon_cb.tx_serial;
            end

            repeat (CLKS_PER_BIT) @(vif.mon_cb);

            if (vif.mon_cb.tx_serial != 1'b1) begin
                $error("UART monitor error: invalid stop bit");
            end

            trans      = new();
            trans.data = received_data;

            uart_cg.sample();

            mon2scb.put(trans);
        end
    endtask;

endclass
