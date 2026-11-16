`timescale 1ns / 1ps

module receive_display (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire [7:0]  data,
    output reg  [23:0] digits,
    output reg  [5:0]  digit_enable
);

reg accepted;
reg [3:0] hex_digit;

always @(*) begin
    accepted = 1'b1;
    if (data >= "0" && data <= "9")
        hex_digit = data[3:0];
    else if (data >= "A" && data <= "F")
        hex_digit = data[3:0] + 4'd9;
    else if (data >= "a" && data <= "f")
        hex_digit = data[3:0] + 4'd9;
    else begin
        accepted = 1'b0;
        hex_digit = 4'd0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        digits <= 24'd0;
        digit_enable <= 6'd0;
    end else if (valid && accepted) begin
        digits <= {digits[19:0], hex_digit};
        digit_enable <= {digit_enable[4:0], 1'b1};
    end
end

endmodule
