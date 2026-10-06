`timescale 1ns/1ps
module tb_uart_tx;

    reg clk = 0, rst_n = 0, tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tick_16x, tx, tx_busy;

    always #10 clk = ~clk;   // 50 MHz

    baud_gen #(.clk_freq(50000000), .Baud(115200)) bg (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x));

    uart_tx dut (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx(tx));

    localparam BIT_CLKS = 27 * 16;   // clock cycles per UART bit

    reg [7:0] got;
    integer i, errors = 0;

    task send_and_check(input [7:0] d);
        begin
            @(posedge clk); tx_data <= d; tx_start <= 1'b1;
            @(posedge clk); tx_start <= 1'b0;

            @(negedge tx);                          // start bit begins
            repeat (BIT_CLKS/2) @(posedge clk);     // middle of start bit
            if (tx !== 1'b0) begin
                $display("FAIL: start bit not 0"); errors = errors + 1;
            end

            for (i = 0; i < 8; i = i + 1) begin     // LSB first
                repeat (BIT_CLKS) @(posedge clk);
                got[i] = tx;
            end

            repeat (BIT_CLKS) @(posedge clk);       // middle of stop bit
            if (tx !== 1'b1) begin
                $display("FAIL: stop bit not 1"); errors = errors + 1;
            end

            if (got !== d) begin
                $display("FAIL: sent %h, decoded %h", d, got); errors = errors + 1;
            end else
                $display("PASS: sent %h, decoded %h", d, got);

            wait (tx_busy == 1'b0);                 // let the frame finish
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
        #100 rst_n = 1;
        repeat (5) @(posedge clk);

        send_and_check(8'h55);
        send_and_check(8'hA3);
        send_and_check(8'h00);
        send_and_check(8'hFF);

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end
endmodule