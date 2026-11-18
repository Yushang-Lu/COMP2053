`timescale 1ns / 1ps
module game_control #(
    parameter SECOND_CYCLES = 100000000
) (
    input wire clk,
    input wire rst,
    input wire start_press,
    input wire recv_valid,
    input wire [7:0] recv_data,
    input wire [2:0] random_bits,
    output reg [1:0] current_state,
    output reg [7:0] score,
    output reg [7:0] time_left,
    output reg [3:0] mole,
    output reg hit,
    output reg miss
);
localparam WAITING = 2'd0, PLAYING = 2'd1, FINISHED = 2'd2;
localparam COUNT_WIDTH = (SECOND_CYCLES > 1) ? $clog2(SECOND_CYCLES) : 1;
reg [1:0] next_state;
reg [COUNT_WIDTH-1:0] second_count;
wire second_end;
wire game_end;
assign second_end = (second_count == SECOND_CYCLES - 1);
assign game_end = second_end && time_left == 8'h01;

// 1. State register.
always @(posedge clk or posedge rst) begin
    if (rst) current_state <= WAITING;
    else current_state <= next_state;
end
// 2. Combinational next-state logic.
always @(*) begin
    next_state = current_state;
    case (current_state)
        WAITING: if (start_press) next_state = PLAYING;
        PLAYING: if (game_end) next_state = FINISHED;
        FINISHED: if (start_press) next_state = PLAYING;
        default: next_state = WAITING;
    endcase
end
// 3. Registered outputs and game datapath. Score/time are packed BCD.
always @(posedge clk or posedge rst) begin
    if (rst) begin
        score <= 8'h00;
        time_left <= 8'h20;
        mole <= 4'd0;
        second_count <= 0;
        hit <= 1'b0;
        miss <= 1'b0;
    end else begin
        hit <= 1'b0;
        miss <= 1'b0;
        case (current_state)
            WAITING, FINISHED: begin
                second_count <= 0;
                if (start_press) begin
                    score <= 8'h00;
                    time_left <= 8'h20;
                    mole <= {1'b0, random_bits} + 4'd1;
                end
            end
            PLAYING: begin
                if (second_end) begin
                    second_count <= 0;
                    if (time_left[3:0] == 4'd0)
                        time_left <= {time_left[7:4] - 4'd1, 4'd9};
                    else
                        time_left <= time_left - 8'd1;
                end else second_count <= second_count + 1'b1;
                // Deadline wins over a byte received on the same clock.
                if (game_end) mole <= 4'd0;
                else if (recv_valid && recv_data >= 8'h31 && recv_data <= 8'h38) begin
                    if (recv_data[3:0] == mole) begin
                        hit <= 1'b1;
                        mole <= {1'b0, random_bits} + 4'd1;
                        if (score != 8'h99) begin
                            if (score[3:0] == 4'd9)
                                score <= {score[7:4] + 4'd1, 4'd0};
                            else score <= score + 8'd1;
                        end
                    end else miss <= 1'b1;
                end
            end
            default: begin
                score <= 8'h00;
                time_left <= 8'h20;
                mole <= 4'd0;
                second_count <= 0;
            end
        endcase
    end
end
endmodule
