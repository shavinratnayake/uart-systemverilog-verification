interface uart_if(input logic clk);
    
    // Reset
    logic rst_n;

    // Inputs to the UART transmitter
    logic tx_start;
    logic [7:0] tx_data;

    // Outputs from the UART transmitter
    logic tx_serial;
    logic tx_busy;
    logic tx_done;

    // Driver clocking block
    clocking drv_cb @(posedge clk);
        output rst_n;
        output tx_start;
        output tx_data;

        input tx_serial;
        input tx_busy;
        input tx_done;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        default input #1step;

        input rst_n;
        input tx_start;
        input tx_data;
        input tx_serial;
        input tx_busy;
        input tx_done;
    endclocking

    // Driver view of the interface
    modport DRIVER (
        clocking drv_cb
    );

    // Monitor view of the interface
    modport MONITOR (
        clocking mon_cb
    );

endinterface
