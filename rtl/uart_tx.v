module uart_tx(
    input wire clk,
    input wire rst_n,
    input wire tick_16x,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_busy,
    output reg tx 

);

reg [1:0] state,next_state;
reg [3:0] tick_cnt;
reg [2:0] bit_idx;
reg [7:0] shreg;
localparam IDLE=2'd0, START=2'd1,DATA=2'd2,STOP=2'd3;

wire bit_done=tick_16x&&(tick_cnt==4'd15);


//control tx and tx_busy of each state 
always @(*)begin
     if (state==IDLE)begin
      tx=1'b1;
       tx_busy=1'b0;
    end
    else if (state==START)begin
        tx=1'b0;
       tx_busy=1'b1;
    end
    else if (state==DATA)begin
         tx=shreg[0];
         tx_busy=1'b1;
            
    end
    else if(state==STOP)begin
        tx=1'b1;
         tx_busy=1'b1;
    end
    else begin
          tx=1'b1;
          tx_busy=1'b0;
          end
end

//FSM Logic 
    always@(*)begin
       case(state)
       IDLE:begin 
        next_state=(tx_start)?START:IDLE;
                
                end
       START: begin 
             next_state=bit_done?DATA:START;
         
              end
       DATA:begin 
            next_state=(bit_done&&bit_idx==3'd7)?STOP:DATA;
           
            end
       STOP:begin 
            next_state=bit_done?IDLE:STOP;
             
            end
       default:next_state=IDLE;
       endcase
    end

    //control tick_cnt and bit_idx
  always @(posedge clk)begin
      if(~rst_n)begin
        state<=IDLE;
        tick_cnt <= 4'd0;
        bit_idx  <= 3'd0;
        shreg    <= 8'd0;
        end
      else begin
         state<=next_state;
        if(state==IDLE)
            tick_cnt<=4'd0;
        else if(tick_16x)begin
             if(tick_cnt==4'd15)
                tick_cnt<=4'd0;
             else 
                tick_cnt<=tick_cnt+1;
            end
    case(state)
      IDLE:begin
        if(tx_start)begin
             shreg<=tx_data;
             bit_idx<=1'b0;
             
             end
           end
      START :begin
              
             end
      DATA:begin
          if(bit_done&&bit_idx<3'd7)begin
             
                 shreg<=shreg>>1;
                 bit_idx<=bit_idx+1'b1;
             
            end
          
        end
      STOP:begin
           
      end
      default: ;
      endcase
         end
  end 
endmodule