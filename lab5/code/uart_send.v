`timescale 1ns / 1ps

module uart_send(
    input        clk,
    input        rst,
    input        valid,
    input [7:0]  data,
    output reg   dout
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;
localparam BIT_CYCLES = 10416;

reg [1:0] current_state;
reg [1:0] next_state;
reg [13:0] bit_count;
reg [2:0] bit_index;
reg [7:0] data_reg;

always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    next_state = current_state;
    case (current_state)
        IDLE: if (valid) next_state = START;
        START: if (bit_count == BIT_CYCLES - 1) next_state = DATA;
        DATA: if (bit_count == BIT_CYCLES - 1 && bit_index == 7)
                  next_state = STOP;
        STOP: if (bit_count == BIT_CYCLES - 1) next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst)
        dout <= 1'b1;
    else begin
        case (current_state)
            START: dout <= 1'b0;
            DATA: dout <= data_reg[bit_index];
            default: dout <= 1'b1;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        bit_count <= 14'd0;
    else if (current_state == IDLE || bit_count == BIT_CYCLES - 1)
        bit_count <= 14'd0;
    else
        bit_count <= bit_count + 1'b1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        bit_index <= 3'd0;
    else if (current_state != DATA)
        bit_index <= 3'd0;
    else if (bit_count == BIT_CYCLES - 1)
        bit_index <= bit_index + 1'b1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        data_reg <= 8'd0;
    else if (current_state == IDLE && valid)
        data_reg <= data;
end

endmodule
