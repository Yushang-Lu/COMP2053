`timescale 1ns / 1ps

module flowing_water_lights #(
    parameter WIDTH = 24,
    parameter [WIDTH-1:0] CNT_MAX_FAST = 199_999,
    parameter [WIDTH-1:0] CNT_MAX_SLOW = 9_999_999
)(
    input wire clk,
    input wire rst,
    input wire freq_ctrl,
    input wire dir_ctrl,
    input wire mode_sel,
    output reg [7:0] led
);
    reg [WIDTH-1:0] cnt;
    reg mode_prev;
    wire [WIDTH-1:0] cnt_max;
    wire cnt_end;
    wire mode_change;

    assign cnt_max = freq_ctrl ? CNT_MAX_FAST : CNT_MAX_SLOW;
    assign cnt_end = (cnt >= cnt_max);
    assign mode_change = (mode_sel != mode_prev);

    always @(posedge clk or posedge rst) begin
        if (rst)
            mode_prev <= 1'b0;
        else
            mode_prev <= mode_sel;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt <= {WIDTH{1'b0}};
        else if (mode_change || cnt_end)
            cnt <= {WIDTH{1'b0}};
        else
            cnt <= cnt + 1'b1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            led <= 8'h01;
        else if (mode_change)
            led <= mode_sel ? 8'h03 : 8'h01;
        else if (cnt_end) begin
            if (mode_sel)
                led <= dir_ctrl ? {led[1:0], led[7:2]} : {led[5:0], led[7:6]};
            else
                led <= dir_ctrl ? {led[0], led[7:1]} : {led[6:0], led[7]};
        end
    end
endmodule
