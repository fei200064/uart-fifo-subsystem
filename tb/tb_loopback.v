`timescale 1ns/1ps
module tb_loopback;
    reg clk = 0, rst_n = 0, tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tick_16x, line, tx_busy;
    wire [7:0] rx_data;
    wire rx_valid, framing_err;

    always #10 clk = ~clk;

    baud_gen #(.clk_freq(50000000), .Baud(115200)) bg (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x));
    uart_tx tx_i (.clk(clk), .rst_n(rst_n), .tick_16x(tick_16x),
                  .tx_start(tx_start), .tx_data(tx_data),
                  .tx_busy(tx_busy), .tx(line));
    uart_rx rx_i (.clk(clk), .rst_n(rst_n), .tick_16x(tick_16x),
                  .rx(line), .rx_data(rx_data),
                  .rx_valid(rx_valid), .framing_err(framing_err));

    integer errors = 0;

    task send_and_check(input [7:0] d);
        begin
           
            @(posedge clk);
            tx_data<=d;
            tx_start<=1'b1;
            @(posedge clk);
            tx_start<=1'b0;
           
            
            @(posedge rx_valid);
            @(posedge clk);
            if(rx_data !== d)begin
              errors=errors+1'b1;
              $display("FAIL:sent %h,decoded %h",d,rx_data);
            end else
               $display("PASS:sent %h,decoded %h",d,rx_data);
           
            wait(tx_busy==1'b0);
        end
    endtask
    initial begin
        #20000000;
        $display("TIMEOUT");
        $finish;
        end
    initial begin
        $dumpfile("tb_loopback.vcd");
         $dumpvars(0, tb_loopback); 
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