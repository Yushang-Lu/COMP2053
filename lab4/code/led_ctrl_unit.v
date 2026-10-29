`timescale 1ns / 1ps

module led_ctrl_unit #(
    parameter [16:0] SCAN_CNT_MAX = 17'd99_999
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display,
    output reg  [7:0]  led_en,
    output reg  [7:0]  led_cx,
    output reg  [7:0]  led_cx1
);

reg [16:0] scan_cnt;
reg [2:0] scan_index;
reg [3:0] display_digit;
reg [7:0] segment_code;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        scan_cnt <= 17'd0;
        scan_index <= 3'd0;
    end else if (scan_cnt == SCAN_CNT_MAX) begin
        scan_cnt <= 17'd0;
        scan_index <= scan_index + 3'd1;
    end else begin
        scan_cnt <= scan_cnt + 17'd1;
    end
end

always @(*) begin
    case (scan_index)
        3'd0: display_digit = display[3:0];
        3'd1: display_digit = display[7:4];
        3'd2: display_digit = display[11:8];
        3'd3: display_digit = display[15:12];
        3'd4: display_digit = display[19:16];
        3'd5: display_digit = display[23:20];
        3'd6: display_digit = display[27:24];
        3'd7: display_digit = display[31:28];
        default: display_digit = 4'h0;
    endcase
end

always @(*) begin
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
    if (!rst) begin
        led_en = 8'b0000_0001 << scan_index;
        if (scan_index < 3'd4)
            led_cx = segment_code;
        else
            led_cx1 = segment_code;
    end
end

endmodule
