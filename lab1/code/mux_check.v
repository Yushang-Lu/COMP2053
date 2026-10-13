`timescale 1ns/1ps

module mux_check;

    reg        en;
    reg        mux_sel;
    reg  [3:0] input_a;
    reg  [3:0] input_b;
    wire [3:0] output_c;
    integer vector_index;
    integer expected_output;
    integer operand_a;
    integer operand_b;

    mux u_mux (
        .en(en),
        .mux_sel(mux_sel),
        .input_a(input_a),
        .input_b(input_b),
        .output_c(output_c)
    );

    initial begin
        for (vector_index = 0; vector_index < 1024; vector_index = vector_index + 1) begin
            {en, mux_sel, input_a, input_b} = vector_index[9:0];
            operand_a = input_a;
            operand_b = input_b;
            if (!en) begin
                expected_output = 15;
            end else if (mux_sel) begin
                expected_output = (operand_a - operand_b + 16) % 16;
            end else begin
                expected_output = (operand_a + operand_b) % 16;
            end
            #1;
            if (output_c !== expected_output[3:0]) begin
                $fatal(1, "FAIL: en=%b sel=%b a=%d b=%d expected=%b actual=%b",
                       en, mux_sel, input_a, input_b, expected_output[3:0], output_c);
            end
        end
        $display("PASS: mux, 1024 combinations checked.");
        $finish;
    end

endmodule
