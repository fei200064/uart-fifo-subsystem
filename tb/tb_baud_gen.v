`timescale 1ns/1ps
module tb_baud_gen;

    reg clk=0;
    reg rst_n=0;
    wire tick_16x;

    always #10 clk=~clk;
    baud_gen #(.clk_freq(50000000),.Baud(115200)) DUT (.clk(clk), .rst_n(rst_n), .tick_16x(tick_16x));

    initial begin
       $dumpfile ("tb_baud_gen.vcd");
       $dumpvars(0,tb_baud_gen);

     #100;
     rst_n=1;

     #100000;
     $finish;

    end

endmodule