`timescale 1ns / 1ps
module lfsr (
    input wire clk,
    input wire rst,
    output reg [15:0] random_value
);
// x^16 + x^14 + x^13 + x^11 + 1; nonzero seed, period 65535.
always @(posedge clk or posedge rst) begin
    if (rst)
        random_value <= 16'hace1;
    else
        random_value <= {random_value[14:0],
            random_value[15] ^ random_value[13] ^
            random_value[12] ^ random_value[10]};
end
endmodule
