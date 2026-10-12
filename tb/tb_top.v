`timescale 1ns/1ps
module tb_top;
   localparam N=8;
   
   reg uart_clk=0,sys_clk=0,rst_n=0;
   reg tx_wr_en=0;
   reg [7:0] tx_wr_data=0;
   wire tx_full;
   reg rx_rd_en=0;
   wire [7:0] rx_rd_data;
   wire rx_empty;
   wire line;
   wire framing_err,overrun_err;

   always #10 uart_clk=~uart_clk;
   always #5 sys_clk = ~sys_clk;

   uart_top dut(
    .uart_clk(uart_clk), .sys_clk(sys_clk), .rst_n(rst_n), .tx_wr_en(tx_wr_en), 
    .tx_wr_data(tx_wr_data), .tx_full(tx_full), .rx_rd_en(rx_rd_en), .rx_rd_data(rx_rd_data),
    .rx_empty(rx_empty), .tx(line), .rx(line), .framing_err(framing_err), .overrun_err(overrun_err)
   );

   reg [7:0] expected [0:N-1];
   integer wr_idx=0,rd_idx=0,errors=0,i;
   reg running=0;

   always @(negedge sys_clk)begin
      if(running &&wr_idx<N && !tx_full)begin
         tx_wr_data=expected[wr_idx];
         tx_wr_en=1;
         wr_idx=wr_idx+1;
      end else
         tx_wr_en=0;
   end

   always @(negedge sys_clk)begin
        if(running && rd_idx<N && !rx_empty)begin
           if(rx_rd_data !== expected[rd_idx])begin
              errors=errors+1'b1;
              $display("FAIL idx %0d:got %h expected %h",rd_idx,rx_rd_data,expected[rd_idx]);
           end 
            rx_rd_en=1;
            rd_idx=rd_idx+1;
          end  else
              rx_rd_en=0;
        end
    initial begin
        #5000000;
        $display("TIMEOUT wr=%0d rd=%0d",wr_idx,rd_idx);
        $finish;
    end

    initial begin
        $dumpfile ("tb_top.vcd");
        $dumpvars(0,tb_top);
        for(i=0;i<N;i=i+1)
           expected[i]=$random;
        #100 rst_n=1;
        repeat (10) @(posedge sys_clk);
        running=1;
        wait (rd_idx==N);
        repeat(3000) @(posedge uart_clk);
        if(errors==0 &&!overrun_err&&rx_empty)
           $display("TEST PASSED :%0d bytes in order,no extras",N);
        else 
           $display ("TEST FAILED:errors=%0d overrun =%b empty=%b",errors,overrun_err,rx_empty);
        $finish;
    end
   endmodule
