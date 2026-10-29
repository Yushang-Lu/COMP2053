`timescale 1ns / 1ps

module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire signal,
    output wire pos_edge
);

reg sig_r0;
reg sig_r1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sig_r0 <= 1'b0;
        sig_r1 <= 1'b0;
    end else begin
        sig_r0 <= signal;
        sig_r1 <= sig_r0;
    end
end

assign pos_edge = sig_r0 & ~sig_r1;

endmodule
