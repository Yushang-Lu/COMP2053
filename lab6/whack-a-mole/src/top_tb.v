`timescale 1ns / 1ps
module top_tb;
reg clk = 1'b0;
reg rst = 1'b1;
reg button_s2 = 1'b0;
reg mute = 1'b0;
reg uart_rx = 1'b1;
wire effect_led;
wire [7:0] led_en, led_cx, led_cx1;
always #5 clk = !clk;
top #(.CLK_HZ(1000), .BIT_CYCLES(16),
    .DEBOUNCE_CYCLES(4), .SCAN_CYCLES(4)) dut (
    .clk(clk), .rst(rst), .button_s2(button_s2), .mute(mute),
    .uart_rx(uart_rx), .effect_led(effect_led),
    .led_en(led_en), .led_cx(led_cx), .led_cx1(led_cx1)
);
task send_byte;
    input [7:0] value;
    integer bit_number;
    begin
        @(negedge clk); uart_rx = 1'b0;
        repeat (16) @(negedge clk);
        for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
            uart_rx = value[bit_number];
            repeat (16) @(negedge clk);
        end
        uart_rx = 1'b1;
        repeat (16) @(negedge clk);
    end
endtask
initial begin
    #30; rst = 1'b0;
    repeat (12) @(negedge clk);
    button_s2 = 1'b1;
    repeat (2) @(negedge clk); button_s2 = 1'b0; // Bounce: ignored.
    repeat (8) @(negedge clk); button_s2 = 1'b1;
    repeat (40) @(negedge clk); button_s2 = 1'b0; // Long hold: one start.
    repeat (12) @(negedge clk);
    send_byte(8'h30 + dut.mole); // Hit, then a deliberately wrong digit.
    send_byte(dut.mole == 4'd1 ? 8'h32 : 8'h31);
    send_byte(8'h0d); // Ignored.
    mute = 1'b1;
    repeat (100) @(negedge clk); mute = 1'b0;
    wait (dut.current_state == 2'd2);
    send_byte(8'h31); // Ignored after finish.
    repeat (3100) @(negedge clk);
    button_s2 = 1'b1;
    repeat (12) @(negedge clk); button_s2 = 1'b0;
    repeat (40) @(negedge clk);
    rst = 1'b1;
    repeat (4) @(negedge clk); rst = 1'b0;
    repeat (20) @(negedge clk);
    $finish;
end
endmodule
