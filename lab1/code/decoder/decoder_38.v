`timescale 1ns/1ps

module decoder_38 (
    input  wire [2:0] en,
    input  wire [2:0] data_in,
    output reg  [7:0] data_out
);

    always @(*) begin
        if (en == 3'b100) begin
            case (data_in)
                3'b000: data_out = 8'b11111110;
                3'b001: data_out = 8'b11111101;
                3'b010: data_out = 8'b11111011;
                3'b011: data_out = 8'b11110111;
                3'b100: data_out = 8'b11101111;
                3'b101: data_out = 8'b11011111;
                3'b110: data_out = 8'b10111111;
                3'b111: data_out = 8'b01111111;
                default: data_out = 8'b11111111;
            endcase
        end else begin
            data_out = 8'b11111111;
        end
    end

endmodule
