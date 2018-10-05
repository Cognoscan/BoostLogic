module RxUart_tb ();

reg clk;            ///< System clock
reg rst;            ///< Reset FIFO
reg x16BaudStrobe;  ///< Strobe at 16x baud rate
reg read;           ///< Read strobe for buffer
reg write;          ///< Write strobe
reg [7:0] dataIn;   ///< Data to transmit

wire [7:0] dataOut; ///< Data from receive buffer
wire rxDataPresent; ///< Receive buffer not empty
wire rxHalfFull;    ///< Receive buffer half full
wire rxFull;        ///< Receive buffer full
wire serial;
wire txDataPresent; ///< Data present in transmit buffer
wire txHalfFull;    ///< Transmit buffer is half full
wire txFull;        ///< Transmit buffer is full

reg [2:0] baudStrobeCount;

integer i;

always #1 clk = ~clk;
always @(posedge clk) baudStrobeCount <= baudStrobeCount + 2'd1;
always @(posedge clk) x16BaudStrobe <= baudStrobeCount == 'd0;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    x16BaudStrobe = 1'b0;
    read = 1'b0;
end

RxUart #(
    .LOG2_DEPTH(4)                 ///< log2(depth of FIFO). Must be an integer
)
uut
(
    .clk(clk),                     ///< System clock
    .rst(rst),                     ///< Reset FIFO
    .x16BaudStrobe(x16BaudStrobe), ///< Strobe at 16x baud rate
    .read(read),                   ///< Read strobe for buffer
    .serialIn(serial),             ///< Serial Receive
    .dataOut(dataOut),             ///< [7:0] Data from receive buffer
    .dataPresent(rxDataPresent),   ///< Receive buffer not empty
    .halfFull(rxHalfFull),         ///< Receive buffer half full
    .full(rxFull)                  ///< Receive buffer full
);

TxUart #(
    .LOG2_DEPTH(4)                 ///< log2(depth of FIFO). Must be an integer
)
stimulus
(
    // Inputs
    .clk(clk),                     ///< System clock
    .rst(rst),                     ///< Reset FIFO
    .x16BaudStrobe(x16BaudStrobe), ///< Strobe at 16x baud rate
    .dataIn(dataIn),               ///< [7:0] Data to transmit
    .write(write),                 ///< Write strobe
    // Outputs
    .serialOut(serial),            ///< Serial transmit
    .dataPresent(txDataPresent),   ///< Data present in transmit buffer
    .halfFull(txHalfFull),         ///< Transmit buffer is half full
    .full(txFull)                  ///< Transmit buffer is full
);

endmodule
