`timescale 1ns/1ps
module tb_sync_fifo;
     localparam WIDTH=8;
     localparam DEPTH =16;

     reg clk=0,rst_n=0;
     reg wr_en=0,rd_en=0;
     reg [WIDTH-1:0]wr_data=0;
     wire [WIDTH-1:0]rd_data;
     wire full,empty;
     wire [$clog2(DEPTH):0]count;

     always #10 clk=~clk;

     sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .wr_data(wr_data), .rd_en(rd_en), .rd_data(rd_data), .full(full), .empty(empty), .count(count));

     integer errors=0;
     integer i;
    integer before;

     task write_one(input[WIDTH-1:0]d);
        begin
           @(negedge clk);
           wr_data=d;
           wr_en=1;
           @(negedge clk);
           wr_en=0;
        end
        endtask

    task read_one(input [WIDTH-1:0]expected);
         begin
            @(negedge clk);
            if(rd_data!==expected)begin
                errors=errors+1'b1;
                $display("FAIL:expected  %h, got %h",expected,rd_data);
            end else 
                $display ("PASS:expected %h, got %h",expected,rd_data);
            rd_en=1;
            @(negedge clk);
            rd_en=0;
         end
         endtask

         task check (input[255:0]name,input cond);
         begin
             if(!cond)begin
                    errors=errors+1;
                    $display("FAIL:%0s",name);
             end else
                  $display("PASS:%0s",name);
         end
         endtask
        
        initial begin #5000000;$display("TIMEOUT");$finish;end
         initial begin
              $dumpfile("tb_sync_fifo.vcd");
              $dumpvars(0,tb_sync_fifo);
              #100 rst_n =1;
              @(negedge clk);

              check("empty after reset",empty===1'b1);

               //Test 1:fill it
              for(i=0;i<DEPTH;i=i+1) write_one(i+1);
                   check("full after 16 writes",full===1'b1);
                   check("count is DEPTH",count==DEPTH);
                
                //Test 2:write while full
                   write_one(8'hEE);
                   check("count unchanged when full",count==DEPTH);

               //Test 3:read everything back in order
             for(i=0;i<DEPTH;i=i+1) read_one(i+1);
                   check("Empty after 16 read",empty===1'b1);
                    check("count is DEPTH",count==0);
          
          //Test 4:read while empty
          @(negedge clk);
          rd_en=1;
          @(negedge clk);
          rd_en=0;
          check ("count still 0 after read when empty",count ==0);

          
          write_one(8'h55);
          write_one(8'hAA);
          before=count;
          @(negedge clk);
          wr_data=8'h77;
          wr_en=1;
          rd_en=1;
          @(negedge clk);
          wr_en=0;
          rd_en=0;
          check("count unchanged on simultaneous read/write",count==before);
          check ("oldest item is now 0xAA",rd_data===8'hAA);
         

          if(errors==0) $display("TEST PASSED");
          else    $display("TEST FAILED:%0d errors",errors);
          $finish;
    end
    endmodule