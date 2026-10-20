`timescale 1ns/1ps

module dff (
    input  wire clk,
    input  wire clr,
    input  wire en,
    input  wire d,
    output reg  q
);

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            q <= 1'b0;
        end else if (en) begin
            q <= d;
        end else begin
            q <= q;
        end
    end

endmodule
