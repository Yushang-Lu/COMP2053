`timescale 1ns / 1ps

module uart_top(
    input  clk,
    input  rst,
    output uart_tx
);

localparam CHAR_CYCLES = 200000;
localparam REPEAT_CYCLES = 25200000;

reg [24:0] wait_count;
reg [3:0] char_index;
reg valid;
reg [7:0] data;

uart_send u_uart_send (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .data(data),
    .dout(uart_tx)
);

always @(posedge clk or posedge rst) begin
    if (rst)
        wait_count <= 25'd0;
    else if (wait_count != 0)
        wait_count <= wait_count - 1'b1;
    else if (char_index == 14)
        wait_count <= REPEAT_CYCLES - 1;
    else
        wait_count <= CHAR_CYCLES - 1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        char_index <= 4'd0;
    else if (wait_count == 0) begin
        if (char_index == 14)
            char_index <= 4'd0;
        else
            char_index <= char_index + 1'b1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        valid <= 1'b0;
    else
        valid <= (wait_count == 0);
end

always @(posedge clk or posedge rst) begin
    if (rst)
        data <= 8'd0;
    else if (wait_count == 0) begin
        case (char_index)
            0: data <= "h";
            1: data <= "i";
            2: data <= "t";
            3: data <= "s";
            4: data <= "z";
            5: data <= "2";
            6: data <= "0";
            7: data <= "2";
            8: data <= "5";
            9: data <= "3";
            10: data <= "1";
            11: data <= "0";
            12: data <= "5";
            13: data <= "9";
            14: data <= "9";
            default: data <= "h";
        endcase
    end
end

endmodule
