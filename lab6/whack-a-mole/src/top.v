`timescale 1ns / 1ps
module top #(
    parameter CLK_HZ = 100000000,
    parameter BIT_CYCLES = 10416,
    parameter DEBOUNCE_CYCLES = 2000000,
    parameter SCAN_CYCLES = 100000
) (
    input wire clk,
    input wire rst,
    input wire button_s2,
    input wire mute,
    input wire uart_rx,
    output wire effect_led,
    output wire [7:0] led_en,
    output wire [7:0] led_cx,
    output wire [7:0] led_cx1
);
wire start_press;
wire recv_valid;
wire [7:0] recv_data;
wire [15:0] random_value;
wire [1:0] current_state;
wire [7:0] score;
wire [7:0] time_left;
wire [3:0] mole;
wire hit;
wire miss;
wire [31:0] display;
wire [7:0] digit_enable;
key_press #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_key_press (
    .clk(clk), .rst(rst), .key_in(button_s2), .press(start_press)
);
uart_recv #(.BIT_CYCLES(BIT_CYCLES)) u_uart_recv (
    .clk(clk), .rst(rst), .din(uart_rx), .valid(recv_valid), .data(recv_data)
);
lfsr u_lfsr (.clk(clk), .rst(rst), .random_value(random_value));
game_control #(.SECOND_CYCLES(CLK_HZ)) u_game_control (
    .clk(clk), .rst(rst), .start_press(start_press),
    .recv_valid(recv_valid), .recv_data(recv_data),
    .random_bits(random_value[2:0]), .current_state(current_state),
    .score(score), .time_left(time_left), .mole(mole), .hit(hit), .miss(miss)
);
game_display u_game_display (
    .current_state(current_state), .score(score), .time_left(time_left),
    .mole(mole), .display(display), .digit_enable(digit_enable)
);
segment_scan #(.SCAN_CYCLES(SCAN_CYCLES)) u_segment_scan (
    .clk(clk), .rst(rst), .display(display), .digit_enable(digit_enable),
    .led_en(led_en), .led_cx(led_cx), .led_cx1(led_cx1)
);
effect_led #(.CLK_HZ(CLK_HZ)) u_effect_led (
    .clk(clk), .rst(rst), .mute(mute), .current_state(current_state),
    .hit(hit), .miss(miss), .led(effect_led)
);
endmodule
