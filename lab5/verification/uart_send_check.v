`timescale 1ns / 1ps

module uart_send_check;

reg clk = 0;
reg rst = 1;
reg valid = 0;
reg [7:0] data = 0;
wire dout;
integer value_index;
integer phase_index;
integer bit_number;
integer cycle_index;
reg [9:0] expected_frame;
time frame_start;

uart_send dut (
    .clk(clk), .rst(rst), .valid(valid), .data(data), .dout(dout)
);

always #5 clk = ~clk;

task reset_core;
    begin
        @(negedge clk);
        #2 rst = 1;
        valid = 0;
        #1;
        if (dout !== 1 || dut.current_state !== 0 ||
            dut.bit_count !== 0 || dut.bit_index !== 0)
            $fatal(1, "Asynchronous reset failed");
        @(negedge clk);
        rst = 0;
    end
endtask

task send_and_check;
    input [7:0] payload;
    begin
        @(negedge clk);
        data = payload;
        valid = 1;
        @(posedge clk);
        #1;
        @(negedge clk);
        valid = 0;
        data = ~payload;
        @(posedge clk);
        #1;
        frame_start = $time - 1;
        expected_frame = {1'b1, payload, 1'b0};
        for (bit_number = 0; bit_number < 10; bit_number = bit_number + 1) begin
            for (cycle_index = 0; cycle_index < 10416; cycle_index = cycle_index + 1) begin
                if (dout !== expected_frame[bit_number])
                    $fatal(1, "Payload %h bit %0d cycle %0d mismatch", payload, bit_number, cycle_index);
                if (dut.bit_count !== ((cycle_index + 1) % 10416))
                    $fatal(1, "Bit counter mismatch");
                if (cycle_index < 10415 &&
                    ((bit_number == 0 && dut.current_state !== 1) ||
                     (bit_number > 0 && bit_number < 9 && dut.current_state !== 2) ||
                     (bit_number == 9 && dut.current_state !== 3)))
                    $fatal(1, "State mismatch");
                @(negedge clk);
                valid = (cycle_index == 20);
                data = ~payload;
                @(posedge clk);
                #1;
            end
        end
        valid = 0;
        if (dut.current_state !== 0 || dout !== 1 ||
            $time - 1 - frame_start != 1041600)
            $fatal(1, "Frame length or return to IDLE failed");
        repeat (3) begin
            @(posedge clk);
            #1;
            if (dut.current_state !== 0 || dout !== 1)
                $fatal(1, "Busy request was incorrectly queued");
        end
    end
endtask

initial begin
    #1;
    reset_core;
    for (value_index = 0; value_index < 256; value_index = value_index + 1)
        send_and_check(value_index[7:0]);
    for (phase_index = 0; phase_index < 4; phase_index = phase_index + 1) begin
        reset_core;
        if (phase_index != 0) begin
            @(negedge clk);
            data = 8'h55;
            valid = 1;
            @(negedge clk);
            valid = 0;
            wait (dut.current_state == phase_index);
            repeat (5) @(negedge clk);
        end
        reset_core;
        send_and_check(8'hA5);
    end
    $display("PASS: 256 bytes, cycle-exact frames, data latch, busy requests, four reset phases");
    $finish;
end

initial begin
    #400000000;
    $fatal(1, "Core verification timeout");
end

endmodule
