`timescale 1ns / 1ps

module led_ctrl_unit_tb;

reg clk;
reg rst;
reg [31:0] display;
wire [7:0] led_en;
wire [7:0] led_cx;
wire [7:0] led_cx1;

led_ctrl_unit #(
    .SCAN_CNT_MAX(17'd9)
) u_led_ctrl_unit (
    .clk(clk),
    .rst(rst),
    .display(display),
    .led_en(led_en),
    .led_cx(led_cx),
    .led_cx1(led_cx1)
);

initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    rst = 1'b1;
    display = 32'h2531_0599;
    #20 rst = 1'b0;
    #1800 $finish;
end

endmodule
