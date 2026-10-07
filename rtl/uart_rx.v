module uart_rx(
    input wire clk,
    input wire rst_n,
    input wire tick_16x,
    input wire rx,
    output reg [7:0]rx_data,
    output reg rx_valid,
    output reg framing_err

);
localparam IDLE=2'd0,START=2'd1,DATA=2'd2,STOP=2'd3;

reg [1:0]state,next_state;
reg[3:0] tick_cnt;
reg[2:0] bit_idx;
reg[7:0] shreg;
reg rx_ff1,rx_ff2;

wire half_done=tick_16x&&(tick_cnt==4'd7);
wire bit_done=tick_16x&&(tick_cnt==4'd15);

//Synchronizer (rx comes from outside and isn't aligned to your clock. Reading it directly can cause metastability. )
always @(posedge clk)begin
   if(~rst_n)begin
      rx_ff1<=1'd1;
      rx_ff2<=1'd1;
   end
   else begin
     rx_ff1<=rx;
     rx_ff2<=rx_ff1;
     end
end

//FSM next_state logic
always @(*)begin 
    next_state=state;
    case(state)
    IDLE:begin
         next_state=rx_ff2?IDLE:START;
    end
    START:begin
         if(half_done)begin
            if(rx_ff2==1'd0)
                next_state=DATA;
            else
                next_state=IDLE;
         end
         
    end
    DATA:begin
         
        if (bit_done&&(bit_idx==3'd7))begin
             next_state=STOP;
         end
       
    end
    STOP:begin
          if(bit_done)
                  next_state=IDLE;
     end 
    default:next_state=IDLE;
    endcase
end

//Datapath
always @(posedge clk)begin
    if(~rst_n)begin
        state<=IDLE;
        tick_cnt <= 4'd0;
        bit_idx  <= 3'd0;
        shreg    <= 8'd0;
        rx_valid<=1'b0;
        framing_err<=1'd0;
        rx_data<=8'd0;
      end
    else begin
       state<=next_state;
       rx_valid<=1'b0;
       framing_err<=1'd0;

       if(state==IDLE)
           tick_cnt<=4'd0;
        else if(tick_16x)begin
             if(state==START&&tick_cnt==4'd7) tick_cnt<=4'd0;
             else 
             tick_cnt<=tick_cnt+1'b1;
        end
    case(state)
      IDLE:begin
        bit_idx  <= 3'd0;
        shreg    <= 8'd0;
      end
      START:begin
          
      end
      DATA:begin
        if(bit_done)begin
             shreg <={rx_ff2,shreg[7:1]};
             bit_idx<=bit_idx+1'd1;
             end
      end
      STOP:begin
          if(bit_done)begin
             if(rx_ff2)begin
                  rx_data<=shreg;
                  rx_valid<=1'd1;
             end
             else begin
                 framing_err<=1'd1;
             end
             
          end
     end 
     default:;
    endcase
   end
end


endmodule