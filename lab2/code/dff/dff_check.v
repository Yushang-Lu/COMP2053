`timescale 1ns/1ps

module dff_check;

    reg clk = 1'b0;
    reg clr = 1'b0;
    reg en = 1'b0;
    reg d = 1'b0;
    wire q;
    integer preset_value;
    integer enable_value;
    integer data_value;
    integer reset_value;
    integer checks = 0;
    reg expected_q;

    always #5 clk = ~clk;

    task check_q;
        input expected_value;
        begin
            checks = checks + 1;
            if (q !== expected_value) begin
                $fatal(1, "dff at %0t: expected %b, got %b",
                       $time, expected_value, q);
            end
        end
    endtask

    initial begin
        #2 clr = 1'b1;
        #1 check_q(1'b0);
        for (preset_value = 0; preset_value < 2; preset_value = preset_value + 1) begin
            for (enable_value = 0; enable_value < 2; enable_value = enable_value + 1) begin
                for (data_value = 0; data_value < 2; data_value = data_value + 1) begin
                    for (reset_value = 0; reset_value < 2; reset_value = reset_value + 1) begin
                        @(negedge clk);
                        clr = 1'b0;
                        en = 1'b1;
                        d = preset_value[0];
                        @(posedge clk);
                        #1 check_q(preset_value[0]);
                        @(negedge clk);
                        en = enable_value[0];
                        d = data_value[0];
                        #2 clr = reset_value[0];
                        expected_q = reset_value[0] ? 1'b0 : preset_value[0];
                        #1 check_q(expected_q);
                        @(posedge clk);
                        expected_q = reset_value[0] ? 1'b0 :
                                     (enable_value[0] ? data_value[0] : preset_value[0]);
                        #1 check_q(expected_q);
                        #1 clr = 1'b0;
                        #1 check_q(expected_q);
                    end
                end
            end
        end
        $display("PASS: dff_check, 16 state/input combinations, %0d checks.", checks);
        $finish;
    end

    initial begin
        #10000 $fatal(1, "dff_check timeout");
    end

    dff u_dff (
        .clk (clk),
        .clr (clr),
        .en  (en),
        .d   (d),
        .q   (q)
    );

endmodule
