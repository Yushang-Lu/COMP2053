`timescale 1ns / 1ps
module game_display (
    input wire [1:0] current_state,
    input wire [7:0] score,
    input wire [7:0] time_left,
    input wire [3:0] mole,
    output wire [31:0] display,
    output wire [7:0] digit_enable
);
assign display = {score, time_left, 12'h000, mole};
assign digit_enable = (current_state == 2'd1) ? 8'hf1 : 8'hf0;
endmodule
