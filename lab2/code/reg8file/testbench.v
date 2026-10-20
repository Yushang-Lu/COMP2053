`timescale 1ns/1ps

module testbench;

    reg clk;
    reg clr;
    reg en;
    reg [7:0] d;
    reg [2:0] wsel;
    reg [2:0] rsel;
    wire [7:0] q;
    integer checks = 0;

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
        $display("PASS: testbench, %0d checks, report waveform ends at 100 ns.", checks);
        $finish;
    end

    task check_q;
        input [7:0] expected_q;
        begin
            checks = checks + 1;
            if (q !== expected_q) begin
                $fatal(1, "testbench at %0t: rsel=%0d expected %h, got %h",
                       $time, rsel, expected_q, q);
            end
        end
    endtask

    initial begin
        #1 check_q(8'h00);
        #15 check_q(8'h00);
        #20 check_q(8'h00);
        #7 check_q(8'h3c);
        #6 check_q(8'h3c);
        #4 check_q(8'ha5);
        #6 check_q(8'ha5);
        #4 check_q(8'h00);
        #10 check_q(8'h00);
        #10 check_q(8'h00);
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
