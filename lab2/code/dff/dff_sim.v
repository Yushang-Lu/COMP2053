`timescale 1ns/1ps

module dff_sim;

    reg clk;
    reg clr;
    reg en;
    reg d;
    wire q;

    initial begin
        clr = 1'b1;
        en = 1'b0;
        clk = 1'b0;
        d = 1'b0;

        #10;
        clr = 1'b0;
        en = 1'b1;
        d = 1'b1;
        #10 d = 1'b0;
        #10 d = 1'b1;

        #10;
        en = 1'b0;
        d = 1'b0;

        #10 clr = 1'b1;
        #50 $finish;
    end

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("dff_sim.vcd");
            $dumpvars(0, dff_sim);
        end
    end

    always #5 clk = ~clk;

    dff u_dff (
        .clk (clk),
        .clr (clr),
        .en  (en),
        .d   (d),
        .q   (q)
    );

endmodule
