`timescale 1ns / 1ps
module effect_led #(
    parameter CLK_HZ = 100000000
) (
    input wire clk,
    input wire rst,
    input wire mute,
    input wire [1:0] current_state,
    input wire hit,
    input wire miss,
    output wire led
);
localparam WAITING = 2'd0, PLAYING = 2'd1, FINISHED = 2'd2;
localparam TIMER_WIDTH = $clog2(3 * CLK_HZ + 1);
localparam PHASE_WIDTH = $clog2(CLK_HZ + 1);
(* ASYNC_REG = "TRUE" *) reg mute_sync0;
(* ASYNC_REG = "TRUE" *) reg mute_sync1;
reg [1:0] previous_state;
reg [1:0] event_kind;
reg [TIMER_WIDTH-1:0] event_left;
reg [TIMER_WIDTH-1:0] finish_left;
reg [2:0] mode;
reg [2:0] previous_mode;
reg [PHASE_WIDTH-1:0] half_period;
reg [PHASE_WIDTH-1:0] phase_count;
reg wave;
wire restart_phase;
assign restart_phase = (mode != previous_mode) ||
    (current_state == PLAYING && (hit || miss));
assign led = !rst && !mute_sync1 && mode != 3'd0 && wave;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        mute_sync0 <= 1'b0;
        mute_sync1 <= 1'b0;
    end else begin
        mute_sync0 <= mute;
        mute_sync1 <= mute_sync0;
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        previous_state <= WAITING;
        event_kind <= 2'd0;
        event_left <= 0;
        finish_left <= 0;
    end else begin
        previous_state <= current_state;
        if (current_state != PLAYING) begin
            event_left <= 0;
            event_kind <= 2'd0;
        end else if (hit || miss) begin
            event_left <= CLK_HZ / 2;
            event_kind <= hit ? 2'd1 : 2'd2;
        end else if (event_left != 0) event_left <= event_left - 1'b1;
        if (current_state != FINISHED) finish_left <= 0;
        else if (previous_state != FINISHED) finish_left <= 3 * CLK_HZ - 1;
        else if (finish_left != 0) finish_left <= finish_left - 1'b1;
    end
end
always @(*) begin
    mode = 3'd0;
    half_period = 1;
    case (current_state)
        WAITING: begin mode = 3'd1; half_period = CLK_HZ / 2; end
        PLAYING: begin
            if (event_left != 0 && event_kind == 2'd1) begin
                mode = 3'd3; half_period = CLK_HZ / 16;
            end else if (event_left != 0 && event_kind == 2'd2) begin
                mode = 3'd4; half_period = CLK_HZ / 8;
            end else begin mode = 3'd2; half_period = CLK_HZ / 4; end
        end
        FINISHED: begin
            if (previous_state != FINISHED || finish_left != 0) begin
                mode = 3'd5; half_period = CLK_HZ / 6;
            end
        end
        default: begin mode = 3'd0; half_period = 1; end
    endcase
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        previous_mode <= 3'd0;
        phase_count <= 0;
        wave <= 1'b0;
    end else begin
        previous_mode <= mode;
        if (mode == 3'd0) begin phase_count <= 0; wave <= 1'b0; end
        else if (restart_phase) begin phase_count <= 0; wave <= 1'b1; end
        else if (phase_count == half_period - 1'b1) begin
            phase_count <= 0;
            wave <= !wave;
        end else phase_count <= phase_count + 1'b1;
    end
end
endmodule
