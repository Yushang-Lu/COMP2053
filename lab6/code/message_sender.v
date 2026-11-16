`timescale 1ns / 1ps

module message_sender #(
    parameter [15:0] GROUP_ID = "05",
    parameter [79:0] STUDENT_ID = "2025310599",
    parameter CHAR_CYCLES = 200000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       press,
    input  wire       done,
    output reg        valid,
    output reg  [7:0] data,
    output reg  [7:0] send_count
);

localparam [103:0] MESSAGE = {GROUP_ID, 8'h2b, STUDENT_ID};
reg active;
reg last_sent;
reg [3:0] char_index;
reg [17:0] wait_count;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        active <= 1'b0;
        last_sent <= 1'b0;
        char_index <= 4'd0;
        wait_count <= 18'd0;
        valid <= 1'b0;
        data <= 8'd0;
    end else begin
        valid <= 1'b0;
        if (!active) begin
            if (press) begin
                active <= 1'b1;
                last_sent <= 1'b0;
                char_index <= 4'd0;
                wait_count <= 18'd0;
            end
        end else if (last_sent) begin
            if (done)
                active <= 1'b0;
        end else if (wait_count != 18'd0)
            wait_count <= wait_count - 18'd1;
        else begin
            valid <= 1'b1;
            data <= MESSAGE[103 - char_index * 8 -: 8];
            wait_count <= CHAR_CYCLES - 1;
            if (char_index == 4'd12)
                last_sent <= 1'b1;
            else
                char_index <= char_index + 4'd1;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        send_count <= 8'h00;
    else if (done) begin
        if (send_count == 8'h99)
            send_count <= 8'h00;
        else if (send_count[3:0] == 4'd9)
            send_count <= {send_count[7:4] + 4'd1, 4'd0};
        else
            send_count <= send_count + 8'd1;
    end
end

endmodule
