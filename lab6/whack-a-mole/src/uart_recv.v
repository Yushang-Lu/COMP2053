`timescale 1ns / 1ps

module uart_recv #(
    parameter BIT_CYCLES = 10416
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       din,
    output reg        valid,
    output reg  [7:0] data
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

(* ASYNC_REG = "TRUE" *) reg din_sync0;
(* ASYNC_REG = "TRUE" *) reg din_sync1;
reg [1:0] current_state;
reg [1:0] next_state;
reg [13:0] bit_count;
reg [2:0] bit_index;
reg [7:0] data_reg;
wire cnt_half;
wire cnt_end;

assign cnt_half = (bit_count == BIT_CYCLES / 2 - 1);
assign cnt_end = (bit_count == BIT_CYCLES - 1);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        din_sync0 <= 1'b1;
        din_sync1 <= 1'b1;
    end else begin
        din_sync0 <= din;
        din_sync1 <= din_sync0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    next_state = current_state;
    case (current_state)
        IDLE: if (!din_sync1) next_state = START;
        START: begin
            if (cnt_half && din_sync1)
                next_state = IDLE;
            else if (cnt_end)
                next_state = DATA;
        end
        DATA: if (cnt_end && bit_index == 3'd7) next_state = STOP;
        STOP: if (cnt_end) next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst)
        bit_count <= 14'd0;
    else if (current_state == IDLE)
        bit_count <= din_sync1 ? 14'd0 : 14'd1;
    else if (cnt_end)
        bit_count <= 14'd0;
    else
        bit_count <= bit_count + 14'd1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        bit_index <= 3'd0;
    else if (current_state != DATA)
        bit_index <= 3'd0;
    else if (cnt_end)
        bit_index <= bit_index + 3'd1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        data_reg <= 8'd0;
    else if (current_state == DATA && cnt_half)
        data_reg[bit_index] <= din_sync1;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid <= 1'b0;
        data <= 8'd0;
    end else begin
        valid <= 1'b0;
        if (current_state == STOP && cnt_half && din_sync1) begin
            valid <= 1'b1;
            data <= data_reg;
        end
    end
end

endmodule
