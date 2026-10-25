`timescale 1ns/1ps

module testbench;

    reg clk;
    reg clr;
    reg en;
    reg [7:0] d;
    reg [2:0] wsel;
    reg [2:0] rsel;
    wire [7:0] q;

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        clr = 1'b1;
        en = 1'b0;
        d = 8'h00;
        wsel = 3'd0;
        rsel = 3'd0;

        #10;
        clr = 1'b0;
        en = 1'b1;
        wsel = 3'd1;
        d = 8'h3c;
        #10;
        en = 1'b0;
        d = 8'h00;

        #10;
        en = 1'b1;
        wsel = 3'd6;
        d = 8'ha5;
        #10;
        en = 1'b0;
        d = 8'h00;
        wsel = 3'd0;

        #2 rsel = 3'd1;
        #10 rsel = 3'd6;
        #10 clr = 1'b1;
        #8 clr = 1'b0;
        #2 rsel = 3'd1;
        #10 rsel = 3'd6;
        #18;
        $finish;
    end

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("reg8file_sim.vcd");
            $dumpvars(0, testbench);
        end
    end

    reg8file u_reg8file (
        .clk  (clk),
        .clr  (clr),
        .en   (en),
        .d    (d),
        .wsel (wsel),
        .rsel (rsel),
        .q    (q)
    );

endmodule
