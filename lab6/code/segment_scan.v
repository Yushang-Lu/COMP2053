`timescale 1ns / 1ps

module segment_scan #(
    parameter SCAN_CYCLES = 100000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display,
    input  wire [7:0]  digit_enable,
    output reg  [7:0]  led_en,
    output reg  [7:0]  led_cx,
    output reg  [7:0]  led_cx1
);

reg [16:0] scan_count;
reg [2:0] scan_index;
reg [3:0] display_digit;
reg [7:0] segment_code;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        scan_count <= 17'd0;
        scan_index <= 3'd0;
    end else if (scan_count == SCAN_CYCLES - 1) begin
        scan_count <= 17'd0;
        scan_index <= scan_index + 3'd1;
    end else
        scan_count <= scan_count + 17'd1;
end

always @(*) begin
    display_digit = display[scan_index * 4 +: 4];
    case (display_digit)
        4'h0: segment_code = 8'hfc;
        4'h1: segment_code = 8'h60;
        4'h2: segment_code = 8'hda;
        4'h3: segment_code = 8'hf2;
        4'h4: segment_code = 8'h66;
        4'h5: segment_code = 8'hb6;
        4'h6: segment_code = 8'hbe;
        4'h7: segment_code = 8'he0;
        4'h8: segment_code = 8'hfe;
        4'h9: segment_code = 8'hf6;
        4'ha: segment_code = 8'hee;
        4'hb: segment_code = 8'h3e;
        4'hc: segment_code = 8'h9c;
        4'hd: segment_code = 8'h7a;
        4'he: segment_code = 8'h9e;
        4'hf: segment_code = 8'h8e;
        default: segment_code = 8'h00;
    endcase
end

always @(*) begin
    led_en = 8'h00;
    led_cx = 8'h00;
    led_cx1 = 8'h00;
    if (!rst && digit_enable[scan_index]) begin
        led_en = 8'b0000_0001 << scan_index;
        if (scan_index < 3'd4)
            led_cx = segment_code;
        else
            led_cx1 = segment_code;
    end
end

endmodule
