`timescale 1ns / 1ps

module top #(
    parameter [15:0] GROUP_ID = "05",
    parameter [79:0] STUDENT_ID = "2025310599",
    parameter BIT_CYCLES = 10416,
    parameter CHAR_CYCLES = 200000,
    parameter DEBOUNCE_CYCLES = 2000000,
    parameter SCAN_CYCLES = 100000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       button_s2,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led_en,
    output wire [7:0] led_cx,
    output wire [7:0] led_cx1
);

wire send_press;
wire recv_valid;
wire [7:0] recv_data;
wire send_valid;
wire [7:0] send_data;
wire send_done;
wire [7:0] send_count;
wire [23:0] recv_digits;
wire [5:0] recv_enable;

key_press #(
    .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
) u_key_press (
    .clk(clk), .rst(rst), .key_in(button_s2), .press(send_press)
);

uart_recv #(
    .BIT_CYCLES(BIT_CYCLES)
) u_uart_recv (
    .clk(clk), .rst(rst), .din(uart_rx),
    .valid(recv_valid), .data(recv_data)
);

message_sender #(
    .GROUP_ID(GROUP_ID), .STUDENT_ID(STUDENT_ID),
    .CHAR_CYCLES(CHAR_CYCLES)
) u_message_sender (
    .clk(clk), .rst(rst), .press(send_press), .done(send_done),
    .valid(send_valid), .data(send_data), .send_count(send_count)
);

uart_send #(
    .BIT_CYCLES(BIT_CYCLES)
) u_uart_send (
    .clk(clk), .rst(rst), .valid(send_valid), .data(send_data),
    .dout(uart_tx), .done(send_done)
);

receive_display u_receive_display (
    .clk(clk), .rst(rst), .valid(recv_valid), .data(recv_data),
    .digits(recv_digits), .digit_enable(recv_enable)
);

segment_scan #(
    .SCAN_CYCLES(SCAN_CYCLES)
) u_segment_scan (
    .clk(clk), .rst(rst), .display({send_count, recv_digits}),
    .digit_enable({2'b11, recv_enable}),
    .led_en(led_en), .led_cx(led_cx), .led_cx1(led_cx1)
);

endmodule
