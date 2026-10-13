`timescale 1ns/1ps

module mux_sim;

    wire       en;
    wire       mux_sel;
    wire [3:0] input_a;
    wire [3:0] input_b;
    wire [3:0] output_c;
    reg  [9:0] switch;

    assign {en, mux_sel, input_a, input_b} = switch;

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("mux_sim.vcd");
            $dumpvars(0, mux_sim);
        end
    end

    initial begin
        #0 switch = 10'b0_1_0010_0001;
        #5 switch = 10'b0_0_0010_0001;
        #5 switch = 10'b1_0_0001_0000;
        #5 switch = 10'b1_0_0001_0001;
        #5 switch = 10'b1_0_1000_0100;
        #5 switch = 10'b1_0_0100_0001;
        #5 switch = 10'b1_1_0001_0000;
        #5 switch = 10'b1_1_0001_0001;
        #5 switch = 10'b1_1_1000_0100;
        #5 switch = 10'b1_1_0100_0001;
        #10 $finish;
    end

    mux u_mux (
        .en(en),
        .mux_sel(mux_sel),
        .input_a(input_a),
        .input_b(input_b),
        .output_c(output_c)
    );

endmodule
