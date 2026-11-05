`timescale 1ns / 1ps

module uart_top_check;

reg clk = 0;
reg rst = 1;
wire uart_tx;
reg [119:0] message = "hitsz2025310599";
reg [7:0] received;
integer frame_index;
integer data_index;
time start_time;
time previous_start;
time expected_interval;

uart_top dut (.clk(clk), .rst(rst), .uart_tx(uart_tx));
always #5 clk = ~clk;

task receive_byte;
    begin
        @(negedge uart_tx);
        start_time = $time;
        #52080;
        if (uart_tx !== 0)
            $fatal(1, "Invalid start bit");
        for (data_index = 0; data_index < 8; data_index = data_index + 1) begin
            #104160;
            received[data_index] = uart_tx;
        end
        #104160;
        if (uart_tx !== 1)
            $fatal(1, "Invalid stop bit");
    end
endtask

always @(posedge clk) begin
    #1;
    if (!rst && dut.valid && dut.u_uart_send.current_state !== 0)
        $fatal(1, "Top asserted valid while core was busy");
end

initial begin
    #22 rst = 0;
    for (frame_index = 0; frame_index < 31; frame_index = frame_index + 1) begin
        receive_byte;
        if (received !== message[119 - (frame_index % 15) * 8 -: 8])
            $fatal(1, "Character %0d mismatch: %h", frame_index, received);
        if (frame_index > 0) begin
            expected_interval = (frame_index % 15 == 0) ? 252000000 : 2000000;
            if (start_time - previous_start != expected_interval)
                $fatal(1, "Character interval mismatch");
        end
        previous_start = start_time;
    end
    #2 rst = 1;
    #1;
    if (uart_tx !== 1)
        $fatal(1, "Top reset did not idle TX");
    #20 rst = 0;
    receive_byte;
    if (received !== "h")
        $fatal(1, "Top did not restart from h");
    #2 rst = 1;
    #20 rst = 0;
    @(negedge uart_tx);
    #200000 rst = 1;
    #1;
    if (uart_tx !== 1)
        $fatal(1, "Mid-frame top reset failed");
    #20 rst = 0;
    receive_byte;
    if (received !== "h")
        $fatal(1, "Mid-frame reset did not restart from h");
    $display("PASS: two complete messages, two repeat gaps, 2 ms/252 ms intervals, top reset");
    $finish;
end

initial begin
    #700000000;
    $fatal(1, "Top verification timeout");
end

endmodule
