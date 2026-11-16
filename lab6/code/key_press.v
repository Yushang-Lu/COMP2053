`timescale 1ns / 1ps

module key_press #(
    parameter DEBOUNCE_CYCLES = 2000000
) (
    input  wire clk,
    input  wire rst,
    input  wire key_in,
    output reg  press
);

(* ASYNC_REG = "TRUE" *) reg key_sync0;
(* ASYNC_REG = "TRUE" *) reg key_sync1;
reg key_clean;
reg [20:0] stable_count;

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
        stable_count <= 21'd0;
        key_clean <= 1'b0;
        press <= 1'b0;
    end else begin
        press <= 1'b0;
        if (key_sync1 == key_clean)
            stable_count <= 21'd0;
        else if (stable_count == DEBOUNCE_CYCLES - 1) begin
            stable_count <= 21'd0;
            key_clean <= key_sync1;
            press <= key_sync1;
        end else
            stable_count <= stable_count + 21'd1;
    end
end

endmodule
