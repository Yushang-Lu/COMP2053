`timescale 1ns / 1ps

module official_timing;

always @(uart_send_tb.u_uart_send.current_state) begin
    if ($realtime < 1100000)
        $display("TIMING: t=%0.3f ns current_state=%0d",
                 $realtime, uart_send_tb.u_uart_send.current_state);
end

always @(uart_send_tb.dout) begin
    if ($realtime < 1100000)
        $display("TIMING: t=%0.3f ns dout=%b", $realtime, uart_send_tb.dout);
end

endmodule
