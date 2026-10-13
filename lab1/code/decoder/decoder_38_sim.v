`timescale 1ns/1ps

module decoder_38_sim;

    reg  [2:0] en;
    reg  [2:0] data_in;
    wire [7:0] data_out;
    reg  [7:0] expected_output;
    integer vector_index;

    decoder_38 u_decoder_38 (
        .en(en),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        for (vector_index = 0; vector_index < 64; vector_index = vector_index + 1) begin
            {en, data_in} = vector_index[5:0];
            expected_output = 8'hff;
            if (en == 3'b100) begin
                expected_output[data_in] = 1'b0;
            end
            #1;
            if (data_out !== expected_output) begin
                $fatal(1, "FAIL: en=%b data_in=%b expected=%b actual=%b",
                       en, data_in, expected_output, data_out);
            end
        end
        $display("PASS: decoder_38, 64 combinations checked.");
        $finish;
    end

endmodule
