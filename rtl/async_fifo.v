module sync_2ff #(parameter W=5)(
    input wire clk,
    input wire rst_n,
    input wire [W-1:0] d,
    output reg[W-1:0]q
);
   reg [W-1:0]ff1;

   always@(posedge clk)begin
     if(~rst_n)begin
       ff1<=0;
       q<=0;
       end
       else begin
          ff1<=d;
          q<=ff1;
      end
   end
  
endmodule

module async_fifo #(
    parameter WIDTH=8,
    parameter DEPTH=16
)(
    input wire wclk,wrst_n,
    input wire wr_en,
    input wire [WIDTH-1:0] wr_data,
    output wire full,

    input wire rclk,rrst_n,
    input wire rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire empty
);
localparam AW=$clog2(DEPTH);
reg [WIDTH-1:0]mem[0:DEPTH-1];

reg [AW:0] wr_ptr,rd_ptr;
wire do_write,do_read;
wire [AW:0]wr_gray,rd_gray;
wire [AW:0]wr_ptr_next,wr_gray_next;
wire [AW:0]rd_gray_sync,wr_gray_sync;

assign do_write =(wr_en)&&(!full);
assign do_read=(rd_en)&&(!empty);

assign wr_gray=wr_ptr^(wr_ptr>>1);
assign rd_gray=rd_ptr^(rd_ptr>>1);

assign wr_ptr_next=wr_ptr+1'b1;
assign wr_gray_next=wr_ptr_next^(wr_ptr_next>>1);

//used by empty
sync_2ff #(.W(AW+1)) u_w2r(.clk(rclk), .rst_n(rrst_n), .d(wr_gray), .q(wr_gray_sync));
//used by full
sync_2ff #(.W(AW+1)) u_r2w(.clk(wclk), .rst_n(wrst_n), .d(rd_gray), .q(rd_gray_sync));

assign empty=(rd_gray==wr_gray_sync);
assign full=(wr_gray=={~rd_gray_sync[AW:AW-1],rd_gray_sync[AW-2:0]});

always @(posedge wclk)begin
    if(~wrst_n) begin
       wr_ptr<=0;
      end  
    else if (do_write) begin
          mem[wr_ptr[AW-1:0]]<=wr_data;
          wr_ptr<=wr_ptr+1'b1;
    end
     
end
assign rd_data=mem[rd_ptr[AW-1:0]];
always @(posedge rclk)begin
    if(~rrst_n) begin
       rd_ptr<=0;
      end  
    else if (do_read) begin
          rd_ptr<=rd_ptr+1'b1;
    end
     
end

endmodule
