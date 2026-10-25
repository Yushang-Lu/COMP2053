`timescale 1ns / 1ps

module testbench;
    reg clk;
    reg rst;
    reg freq_ctrl;
    reg dir_ctrl;
    reg mode_sel;
    wire [7:0] led;

    flowing_water_lights #(
        .WIDTH(4),
        .CNT_MAX_FAST(4'd6),
        .CNT_MAX_SLOW(4'd11)
    ) u_flowing_water_lights (
        .clk(clk),
        .rst(rst),
        .freq_ctrl(freq_ctrl),
        .dir_ctrl(dir_ctrl),
        .mode_sel(mode_sel),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        freq_ctrl = 1'b1;
        dir_ctrl = 1'b0;
        mode_sel = 1'b0;
        #20 rst = 1'b0;
        #280 freq_ctrl = 1'b0;
        #360 mode_sel = 1'b1;
        #520 $finish;
    end

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("lab3_sim.vcd");
            $dumpvars(0, testbench);
        end
    end
endmodule
