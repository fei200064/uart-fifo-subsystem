`timescale 1ns/1ps
module tb_async_fifo;
    localparam WIDTH =8;
    localparam DEPTH=16;
    localparam N=1000;

    reg wclk=0,rclk=0;
    reg wrst_n=0,rrst_n=0;
    reg wr_en=0,rd_en=0;
    reg [WIDTH-1:0] wr_data=0;
    wire [WIDTH-1:0]rd_data;
    wire full,empty;

    always #10 wclk=~wclk;
    always #15 rclk=~rclk;

    async_fifo# (.WIDTH(WIDTH), .DEPTH(DEPTH)) dut(
        .wclk(wclk), .wrst_n(wrst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rclk(rclk), .rrst_n(rrst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    reg[WIDTH-1:0] expected [0:N-1];
    integer wr_idx=0;
    integer rd_idx=0;
    integer errors=0;
    integer i;
    reg running=0;

    //writer
    always @(negedge wclk)begin
         if(running && wr_idx<N && !full)begin
             wr_data=expected[wr_idx];
             wr_en=1;
             wr_idx=wr_idx+1;
         end else
            wr_en=0;
    end

    //reader
    always @(negedge rclk)begin
           if(running && rd_idx<N && !empty)begin
             if(rd_data!==expected[rd_idx])begin
                errors=errors+1;
                $display("FAIL idx %0d:got %h expected %h",rd_idx,rd_data,expected[rd_idx]);
                rd_idx=rd_idx+1;
             end
                rd_en=1;
                rd_idx=rd_idx+1;
            end
            else
              rd_en=0;
    end

    initial begin #50000000;
    $display("TIMEOUT:wr_idx=%0d rd_idx=%0d",wr_idx,rd_idx);
    $finish;
    end

    initial begin
        $dumpfile("tb_async_fifo.vcd");
        $dumpvars(0,tb_async_fifo);

        for(i=0;i<N;i=i+1)
             expected[i]=$random;

        #100;
        wrst_n=1;rrst_n=1;
        repeat (5) @(posedge wclk);
        running=1;
       
        wait(rd_idx==N);

        repeat (20)@(posedge rclk);
         if(empty&&rd_idx==N&&wr_idx==N)
              $display("PASS empty");
        else 
              $display("FAIL empty");
        
        if(errors==0) $display ("TEST PASSED:%0d bytes in order",N);
        else
           $display("TEST FAILED:%0d errors",errors);
        $finish;
    end
    endmodule