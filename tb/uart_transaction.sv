class uart_transaction;

    rand logic [7:0] data;

    constraint data_dist_c {
        data dist {
            8'h00 := 10,
            8'hFF := 10,
            8'h55 := 10,
            8'hAA := 10,
            [8'h01:8'h54] := 1,
            [8'h56:8'hA9] := 1,
            [8'hAB:8'hFE] := 1
        };
    }

endclass

