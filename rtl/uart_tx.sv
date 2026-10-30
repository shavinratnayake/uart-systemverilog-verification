`timescale 1ns/1ps



module uart_tx #(
    parameter int CLKS_PER_BIT = 8
)(
    input logic     clk,
    input logic     rst_n,
    input logic     tx_start,
    input logic [7:0] tx_data,

    output logic    tx_serial,
    output logic    tx_busy,
    output logic    tx_done
);

    localparam int CLK_COUNT_WIDTH =
        (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [7:0] data_register;
    logic [2:0] bit_index;
    logic [CLK_COUNT_WIDTH-1:0] clock_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state         <= IDLE;
            data_register <= '0;
            bit_index     <= '0;
            clock_count   <= '0;
            tx_serial     <= 1'b1;
            tx_busy       <= 1'b0;
            tx_done       <= 1'b0;
        end
        else begin
            // tx_done is a one-clock pulse.
            tx_done <= 1'b0;

            case (state)

                IDLE: begin
                    tx_serial   <= 1'b1;
                    tx_busy     <= 1'b0;
                    clock_count <= '0;
                    bit_index <= '0;

                    if (tx_start) begin
                        data_register <= tx_data;
                        tx_busy       <= 1'b1;
                        state         <= START_BIT;
                    end
                end

                START_BIT: begin
                    tx_serial <= 1'b0;
                    tx_busy   <= 1'b1;

                    if (clock_count == CLK_COUNT_WIDTH'(CLKS_PER_BIT - 1)) begin
                        clock_count <= '0;
                        state       <= DATA_BITS;
                    end
                    else begin
                        clock_count <= clock_count + 1;
                    end
                end

                DATA_BITS: begin
                    tx_serial <= data_register[bit_index];
                    tx_busy   <= 1'b1;

                    if (clock_count == CLK_COUNT_WIDTH'(CLKS_PER_BIT - 1)) begin
                        clock_count <= '0;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state     <= STOP_BIT;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clock_count <= clock_count + 1;
                    end
                end

                STOP_BIT: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b1;

                    if (clock_count == CLK_COUNT_WIDTH'(CLKS_PER_BIT - 1)) begin
                        clock_count <= '0;
                        tx_busy     <= 1'b0;
                        tx_done     <= 1'b1;
                        state       <= IDLE;
                    end
                    else begin
                        clock_count <= clock_count + 1;
                    end
                end

                default: begin
                    state     <= IDLE;
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_done   <= 1'b0;
                end

            endcase
        end
    end

endmodule

