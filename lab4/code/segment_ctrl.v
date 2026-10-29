`timescale 1ns / 1ps

module segment_ctrl #(
    parameter [16:0] SCAN_CNT_MAX = 17'd99_999,
    parameter [20:0] DEBOUNCE_CNT_MAX = 21'd1_999_999,
    parameter [23:0] TICK_CNT_MAX = 24'd9_999_999
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       mode_sel,
    input  wire       button_s2,
    input  wire       button_s3,
    output wire [7:0] led_en,
    output wire [7:0] led_cx,
    output wire [7:0] led_cx1
);

wire s2_clean;
wire s3_clean;
wire s2_press;
wire s3_raw_press;
wire s3_clean_press;
wire [31:0] display;
reg [7:0] count_raw;
reg [7:0] count_clean;
reg [7:0] count_auto;
reg [23:0] tick_cnt;
reg running;

function [7:0] next_bcd;
    input [7:0] value;
    begin
        if (value == 8'h99)
            next_bcd = 8'h00;
        else if (value[3:0] == 4'd9)
            next_bcd = {value[7:4] + 4'd1, 4'd0};
        else
            next_bcd = value + 8'd1;
    end
endfunction

key_debounce #(
    .DEBOUNCE_CNT_MAX(DEBOUNCE_CNT_MAX)
) u_s2_debounce (
    .clk(clk),
    .rst(rst),
    .key_in(button_s2),
    .key_out(s2_clean)
);

key_debounce #(
    .DEBOUNCE_CNT_MAX(DEBOUNCE_CNT_MAX)
) u_s3_debounce (
    .clk(clk),
    .rst(rst),
    .key_in(button_s3),
    .key_out(s3_clean)
);

edge_detect u_s2_edge (
    .clk(clk),
    .rst(rst),
    .signal(s2_clean),
    .pos_edge(s2_press)
);

edge_detect u_s3_raw_edge (
    .clk(clk),
    .rst(rst),
    .signal(button_s3),
    .pos_edge(s3_raw_press)
);

edge_detect u_s3_clean_edge (
    .clk(clk),
    .rst(rst),
    .signal(s3_clean),
    .pos_edge(s3_clean_press)
);

always @(posedge clk or posedge rst) begin
    if (rst)
        count_raw <= 8'h00;
    else if (s3_raw_press)
        count_raw <= next_bcd(count_raw);
end

always @(posedge clk or posedge rst) begin
    if (rst)
        count_clean <= 8'h00;
    else if (s3_clean_press)
        count_clean <= next_bcd(count_clean);
end

always @(posedge clk or posedge rst) begin
    if (rst)
        running <= 1'b1;
    else if (s2_press)
        running <= ~running;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tick_cnt <= 24'd0;
        count_auto <= 8'h00;
    end else if (running && !s2_press) begin
        if (tick_cnt == TICK_CNT_MAX) begin
            tick_cnt <= 24'd0;
            if (count_auto == 8'h20)
                count_auto <= 8'h00;
            else
                count_auto <= next_bcd(count_auto);
        end else begin
            tick_cnt <= tick_cnt + 24'd1;
        end
    end
end

assign display = mode_sel ? 32'h2531_0599 :
                            {8'h99, count_raw, count_clean, count_auto};

led_ctrl_unit #(
    .SCAN_CNT_MAX(SCAN_CNT_MAX)
) u_led_ctrl_unit (
    .clk(clk),
    .rst(rst),
    .display(display),
    .led_en(led_en),
    .led_cx(led_cx),
    .led_cx1(led_cx1)
);

endmodule
