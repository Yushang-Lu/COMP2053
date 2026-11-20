`timescale 1ns / 1ps

module top_tb;

localparam BIT_CYCLES = 16;
localparam BIT_TIME = BIT_CYCLES * 10;
localparam [103:0] EXPECTED_MESSAGE = "05+2025310599";

reg clk = 1'b0;
reg rst = 1'b1;
reg button_s2 = 1'b0;
reg uart_rx = 1'b1;
wire uart_tx;
wire [7:0] led_en;
wire [7:0] led_cx;
wire [7:0] led_cx1;
integer frames = 0;
integer messages;
integer bit_number;
integer scan_number;
reg [7:0] received_byte;
reg previous_valid = 1'b0;
reg [7:0] expected_segments;
reg [7:0] expected_enable;
time frame_start;
time previous_start = 0;

top #(
    .GROUP_ID("05"),
    .BIT_CYCLES(BIT_CYCLES),
    .CHAR_CYCLES(320),
    .DEBOUNCE_CYCLES(4),
    .SCAN_CYCLES(4)
) dut (
    .clk(clk), .rst(rst), .button_s2(button_s2),
    .uart_rx(uart_rx), .uart_tx(uart_tx),
    .led_en(led_en), .led_cx(led_cx), .led_cx1(led_cx1)
);

always #5 clk = ~clk;

function [7:0] encode;
    input [3:0] digit;
    begin
        case (digit)
            4'h0: encode = 8'hfc;
            4'h1: encode = 8'h60;
            4'h2: encode = 8'hda;
            4'h3: encode = 8'hf2;
            4'h4: encode = 8'h66;
            4'h5: encode = 8'hb6;
            4'h6: encode = 8'hbe;
            4'h7: encode = 8'he0;
            4'h8: encode = 8'hfe;
            4'h9: encode = 8'hf6;
            4'ha: encode = 8'hee;
            4'hb: encode = 8'h3e;
            4'hc: encode = 8'h9c;
            4'hd: encode = 8'h7a;
            4'he: encode = 8'h9e;
            4'hf: encode = 8'h8e;
            default: encode = 8'h00;
        endcase
    end
endfunction

always @(negedge clk) begin
    #1;
    if (!rst && previous_valid && dut.recv_valid)
        $fatal(1, "RX valid lasts longer than one clock");
    previous_valid = dut.recv_valid;
    scan_number = dut.u_segment_scan.scan_index;
    expected_enable = 8'd0;
    expected_segments = 8'd0;
    if (!rst && dut.u_segment_scan.digit_enable[scan_number]) begin
        expected_enable = 8'b1 << scan_number;
        expected_segments = encode(dut.u_segment_scan.display[scan_number * 4 +: 4]);
    end
    if (led_en !== expected_enable)
        $fatal(1, "Digit enable mismatch");
    if (scan_number < 4) begin
        if (led_cx !== expected_segments || led_cx1 !== 8'd0)
            $fatal(1, "Low bank segments mismatch");
    end else if (led_cx1 !== expected_segments || led_cx !== 8'd0)
        $fatal(1, "High bank segments mismatch");
end

initial begin
    forever begin
        @(negedge uart_tx);
        if (!rst) begin
            frame_start = $time;
            if (frames % 13 != 0 && frame_start - previous_start != 3200)
                $fatal(1, "Character interval mismatch");
            previous_start = frame_start;
            #(BIT_TIME / 2);
            if (uart_tx !== 1'b0)
                $fatal(1, "Missing start bit");
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                #BIT_TIME;
                received_byte[bit_number] = uart_tx;
            end
            #BIT_TIME;
            if (uart_tx !== 1'b1)
                $fatal(1, "Missing stop bit");
            if (received_byte !== EXPECTED_MESSAGE[103 - (frames % 13) * 8 -: 8])
                $fatal(1, "TX byte %0d mismatch: %h", frames, received_byte);
            frames = frames + 1;
        end
    end
end

task send_byte;
    input [7:0] value;
    integer bit_index;
    begin
        uart_rx = 1'b0;
        #BIT_TIME;
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            uart_rx = value[bit_index];
            #BIT_TIME;
        end
        uart_rx = 1'b1;
        #BIT_TIME;
    end
endtask

task check_display;
    input [23:0] expected_digits;
    input [5:0] expected_mask;
    begin
        if (dut.recv_digits !== expected_digits || dut.recv_enable !== expected_mask)
            $fatal(1, "RX display mismatch: %h / %b", dut.recv_digits, dut.recv_enable);
    end
endtask

initial begin
    #1000000;
    $fatal(1, "Timeout");
end

initial begin
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (5) @(negedge clk);
    check_display(24'h000000, 6'b000000);
    if (dut.send_count !== 8'h00 || uart_tx !== 1'b1)
        $fatal(1, "Reset state mismatch");

    button_s2 = 1'b1;
    repeat (2) @(negedge clk);
    button_s2 = 1'b0;
    repeat (10) @(negedge clk);
    if (dut.u_message_sender.active)
        $fatal(1, "Button bounce triggered a message");

    fork
        begin
            button_s2 = 1'b1;
            repeat (8000) @(negedge clk);
            if (frames != 13 || dut.send_count !== 8'h13)
                $fatal(1, "Held key retriggered or count mismatch");
            button_s2 = 1'b0;
            repeat (20) @(negedge clk);
        end
        begin
            send_byte("0");
            check_display(24'h000000, 6'b000001);
            send_byte("A");
            check_display(24'h00000a, 6'b000011);
            send_byte("1");
            send_byte("b");
            send_byte("2");
            send_byte("F");
            check_display(24'h0a1b2f, 6'b111111);
            send_byte("3");
            check_display(24'ha1b2f3, 6'b111111);
            send_byte(8'h0d);
            send_byte(8'h0a);
            send_byte("G");
            check_display(24'ha1b2f3, 6'b111111);
        end
    join

    for (messages = 1; messages < 8; messages = messages + 1) begin
        button_s2 = 1'b1;
        repeat (12) @(negedge clk);
        button_s2 = 1'b0;
        wait (!dut.u_message_sender.active);
        repeat (20) @(negedge clk);
    end
    if (frames != 104 || dut.send_count !== 8'h04)
        $fatal(1, "Decimal count did not wrap after 99");

    @(negedge clk);
    #2 rst = 1'b1;
    #1;
    if (uart_tx !== 1'b1 || led_en !== 8'd0 ||
        dut.recv_enable !== 6'd0 || dut.send_count !== 8'd0)
        $fatal(1, "Asynchronous reset failed");
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (10) @(negedge clk);
    send_byte("F");
    check_display(24'h00000f, 6'b000001);
    $display("All top tests passed: duplex RX/TX, blanking, scan, debounce, 104 frames, count wrap, reset.");
    $finish;
end

endmodule
