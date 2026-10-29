`timescale 1ns / 1ps

module key_debounce #(
    parameter [20:0] DEBOUNCE_CNT_MAX = 21'd1_999_999
) (
    input  wire clk,
    input  wire rst,
    input  wire key_in,
    output reg  key_out
);

(* ASYNC_REG = "TRUE" *) reg key_sync0;
(* ASYNC_REG = "TRUE" *) reg key_sync1;
reg [20:0] stable_cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        key_sync0 <= 1'b0;
        key_sync1 <= 1'b0;
    end else begin
        key_sync0 <= key_in;
        key_sync1 <= key_sync0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        stable_cnt <= 21'd0;
        key_out <= 1'b0;
    end else if (key_sync1 == key_out) begin
        stable_cnt <= 21'd0;
    end else if (stable_cnt == DEBOUNCE_CNT_MAX) begin
        stable_cnt <= 21'd0;
        key_out <= key_sync1;
    end else begin
        stable_cnt <= stable_cnt + 21'd1;
    end
end

endmodule
