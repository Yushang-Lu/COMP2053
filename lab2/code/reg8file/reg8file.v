`timescale 1ns/1ps

module reg8file (
    input  wire       clk,
    input  wire       clr,
    input  wire       en,
    input  wire [7:0] d,
    input  wire [2:0] wsel,
    input  wire [2:0] rsel,
    output reg  [7:0] q
);

    reg [7:0] regfile [7:0];
    integer reg_index;

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            for (reg_index = 0; reg_index < 8; reg_index = reg_index + 1) begin
                regfile[reg_index] <= 8'h00;
            end
        end else if (en) begin
            regfile[wsel] <= d;
        end else begin
            regfile[wsel] <= regfile[wsel];
        end
    end

    always @(*) begin
        q = regfile[rsel];
    end

endmodule
