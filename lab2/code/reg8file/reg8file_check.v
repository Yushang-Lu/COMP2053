`timescale 1ns/1ps

module reg8file_check;

    reg clk = 1'b0;
    reg clr = 1'b0;
    reg en = 1'b0;
    reg [7:0] d = 8'h00;
    reg [2:0] wsel = 3'd0;
    reg [2:0] rsel = 3'd0;
    wire [7:0] q;
    reg [7:0] expected [7:0];
    integer address;
    integer data_value;
    integer reset_index;
    integer checks = 0;
    integer writes = 0;

    always #5 clk = ~clk;

    task check_q;
        input [7:0] expected_q;
        begin
            checks = checks + 1;
            if (q !== expected_q) begin
                $fatal(1, "reg8file at %0t: rsel=%0d expected %h, got %h",
                       $time, rsel, expected_q, q);
            end
        end
    endtask

    task scan_all;
        integer read_index;
        begin
            for (read_index = 0; read_index < 8; read_index = read_index + 1) begin
                @(negedge clk);
                #1 rsel = read_index[2:0];
                #1 check_q(expected[read_index]);
            end
        end
    endtask

    task write_one;
        input [2:0] write_address;
        input [7:0] write_data;
        begin
            @(negedge clk);
            en = 1'b1;
            wsel = write_address;
            rsel = write_address;
            d = write_data;
            #1 check_q(expected[write_address]);
            @(posedge clk);
            expected[write_address] = write_data;
            writes = writes + 1;
            #1 check_q(write_data);
            @(negedge clk);
            en = 1'b0;
            d = ~write_data;
            #1 check_q(write_data);
        end
    endtask

    initial begin
        #2 clr = 1'b1;
        for (reset_index = 0; reset_index < 8; reset_index = reset_index + 1) begin
            expected[reset_index] = 8'h00;
        end
        #1 check_q(8'h00);
        @(negedge clk);
        clr = 1'b0;
        scan_all;

        for (address = 0; address < 8; address = address + 1) begin
            write_one(address[2:0], 8'h11 * (address + 1));
        end
        scan_all;

        for (data_value = 0; data_value < 256; data_value = data_value + 1) begin
            for (address = 0; address < 8; address = address + 1) begin
                write_one(address[2:0], data_value[7:0]);
                scan_all;
            end
        end

        for (address = 0; address < 8; address = address + 1) begin
            @(negedge clk);
            en = 1'b0;
            wsel = address[2:0];
            rsel = address[2:0];
            d = ~expected[address];
            @(posedge clk);
            #1 check_q(expected[address]);
        end
        scan_all;

        @(negedge clk);
        en = 1'b1;
        d = 8'ha5;
        #2 clr = 1'b1;
        for (reset_index = 0; reset_index < 8; reset_index = reset_index + 1) begin
            expected[reset_index] = 8'h00;
        end
        #1 check_q(8'h00);
        scan_all;
        @(negedge clk);
        en = 1'b0;
        #2 clr = 1'b0;
        #1 check_q(8'h00);
        scan_all;

        write_one(3'd0, 8'h5a);
        write_one(3'd7, 8'ha5);
        scan_all;
        $display("PASS: reg8file_check, 8 addresses x 256 data values, %0d writes, %0d checks.",
                 writes, checks);
        $finish;
    end

    initial begin
        #1000000 $fatal(1, "reg8file_check timeout");
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
