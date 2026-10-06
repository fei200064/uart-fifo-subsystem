module baud_gen(
    input wire clk,
    input wire rst_n,
    output reg tick_16x
);

parameter clk_freq=50000000,Baud=115200;
localparam integer DIV=clk_freq/(Baud*16);
localparam integer W= $clog2(DIV) ;//how many bits do i need to store the counter(minimum bit-width)
reg [W-1:0] cnt;
always@(posedge clk or negedge rst_n)begin
 if(!rst_n)
 begin
     cnt<=0;
     tick_16x<=1'b0;
 end
 else if(cnt==DIV-1)begin
    cnt<=0;
    tick_16x<=1'b1;
 end
 else begin
     cnt<=cnt+1'b1;
     tick_16x<=1'b0;
 end
end
endmodule