`timescale 1ns / 1ps

module edge_detect_tb;

reg clk;
reg rst;
reg signal;
wire pos_edge;

edge_detect u_edge_detect (
    .clk(clk),
    .rst(rst),
    .signal(signal),
    .pos_edge(pos_edge)
);

initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    rst = 1'b1;
    signal = 1'b0;
    #20 rst = 1'b0;
    #12 signal = 1'b1;
    #40 signal = 1'b0;
    #30 signal = 1'b1;
    #30 signal = 1'b0;
    #30 $finish;
end

endmodule
