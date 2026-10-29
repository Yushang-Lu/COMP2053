`timescale 1ns / 1ps

module segment_ctrl_tb;

reg clk;
reg rst;
reg mode_sel;
reg button_s2;
reg button_s3;
wire [7:0] led_en;
wire [7:0] led_cx;
wire [7:0] led_cx1;

segment_ctrl #(
    .SCAN_CNT_MAX(17'd9),
    .DEBOUNCE_CNT_MAX(21'd3),
    .TICK_CNT_MAX(24'd19)
) u_segment_ctrl (
    .clk(clk),
    .rst(rst),
    .mode_sel(mode_sel),
    .button_s2(button_s2),
    .button_s3(button_s3),
    .led_en(led_en),
    .led_cx(led_cx),
    .led_cx1(led_cx1)
);

initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    rst = 1'b1;
    mode_sel = 1'b0;
    button_s2 = 1'b0;
    button_s3 = 1'b0;
    #20 rst = 1'b0;
    #40 button_s3 = 1'b1;
    #10 button_s3 = 1'b0;
    #10 button_s3 = 1'b1;
    #20 button_s3 = 1'b0;
    #10 button_s3 = 1'b1;
    #180 button_s3 = 1'b0;
    #10 button_s3 = 1'b1;
    #10 button_s3 = 1'b0;
    #140 button_s3 = 1'b1;
    #20 button_s3 = 1'b0;
    #10 button_s3 = 1'b1;
    #10 button_s3 = 1'b0;
    #20 button_s3 = 1'b1;
    #200 button_s3 = 1'b0;
    #10 button_s3 = 1'b1;
    #20 button_s3 = 1'b0;
    #160 $finish;
end

endmodule
