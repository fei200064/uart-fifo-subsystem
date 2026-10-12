module uart_top #(
    parameter CLK_FREQ=50000000,
    parameter BAUD =115200
)(
    input wire uart_clk,sys_clk,rst_n,
   
   //sys_clk domain
   input wire tx_wr_en,
   input wire [7:0]tx_wr_data,
   output wire tx_full,
   input wire rx_rd_en,
   output wire [7:0] rx_rd_data,
   output wire rx_empty,

   //serial pins
   output wire tx,
   input wire rx,

   //uart clk domain(see limitation)
   output wire framing_err,
   output wire overrun_err
);

//uart_clk domain
wire tick_16x;
wire tx_busy,tx_start;
wire [7:0] tx_data;
wire tx_empty;
wire [7:0] rx_data;
wire rx_valid,rx_full;

assign tx_start=!tx_empty&&!tx_busy;
assign overrun_err=rx_valid&&rx_full;

//TODO 1:baud_gen on uart_clk
baud_gen #(.clk_freq(CLK_FREQ), .Baud(BAUD)) u_baud (.clk(uart_clk),.rst_n(rst_n), .tick_16x(tick_16x));
async_fifo #(.WIDTH(8), .DEPTH(16))TX_FIFO(.wclk(sys_clk), .wrst_n(rst_n),
 .wr_en(tx_wr_en), .wr_data(tx_wr_data), .full(tx_full),
 .rclk(uart_clk),.rrst_n(rst_n),.rd_en(tx_start),.rd_data(tx_data),.empty(tx_empty));

uart_tx u_tx(.clk(uart_clk), .rst_n(rst_n), .tick_16x(tick_16x),
.tx_start(tx_start), .tx_data(tx_data), .tx_busy(tx_busy), .tx(tx));

uart_rx u_rx(.clk(uart_clk), .rst_n(rst_n),.tick_16x(tick_16x),
.rx(rx), .rx_data(rx_data), .rx_valid(rx_valid), .framing_err(framing_err));

async_fifo #(.WIDTH(8), .DEPTH(16))RX_FIFO(.wclk(uart_clk),.wrst_n(rst_n),.wr_en(rx_valid),
.wr_data(rx_data), .full(rx_full), .rclk(sys_clk), .rrst_n(rst_n),
.rd_en(rx_rd_en), .rd_data(rx_rd_data), .empty(rx_empty));

 
endmodule
