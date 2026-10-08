module sync_fifo#(
    parameter WIDTH=8,
    parameter DEPTH=16
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [WIDTH-1:0] wr_data,
    input wire rd_en,
    output wire [WIDTH-1:0]rd_data,
    output wire full,
    output wire empty,
    output reg [$clog2(DEPTH):0]count //how many items are store now
);

localparam AW=$clog2(DEPTH);
reg [WIDTH-1:0] mem[DEPTH-1:0];
reg [AW-1:0]rd_ptr;
reg [AW-1:0]wr_ptr;
wire do_write,do_read;
assign empty =(count==0);
assign full=(count==DEPTH);

assign do_write=wr_en && !full;
assign do_read=rd_en && !empty;

assign rd_data=mem[rd_ptr];
  
always @(posedge clk)begin
  if(!rst_n)begin
    rd_ptr<=0;
    wr_ptr<=0;
    count<=0;
    end
    else begin
     case({do_write,do_read})
         2'b00:begin
               
         end
         2'b01: begin
                rd_ptr<=rd_ptr+1'b1;
                 count<=count-1'b1;
                end
        2'b10:begin
              mem[wr_ptr]<=wr_data;
              wr_ptr<=wr_ptr+1'b1;
              count<=count+1'b1;
              end
        2'b11:begin
              count<=count;
              rd_ptr<=rd_ptr+1'b1;
              mem[wr_ptr]<=wr_data;
              wr_ptr<=wr_ptr+1'b1;
              end
        default:;
     endcase
    
    
    end
end


endmodule 