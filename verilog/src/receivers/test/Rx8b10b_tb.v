module Rx8b10b_tb ();

parameter FILL_WORD_RD0 = 10'b0011111010; // Send when no data present & RD=-1
parameter FILL_WORD_RD1 = 10'b1100000101; // Send when no data present & RD=1
parameter FILL_WORD_FLIP = 1'b1;          // Flip status of Running Disparity when using fill word
parameter CLK_RATE = 8;                   // Number of clocks per data bit
parameter LOG2_DEPTH = 4;                 // log2(depth of FIFO buffer). Must be an integer.

reg clk;          // System clock
reg rst;          // Reset; synchronous and active high
reg txEnable;     // Enable bit
reg [7:0] dataIn; // Data to transmit
reg writeStrobe;  // Write data to transmit FIFO
reg readStrobe;   // Read data from receive FIFO
reg rxEnable;       // Set to start/enable receiver

wire [7:0] dataOut; // Data received
wire errorDetect;   // Error detected. Does not latch.
wire rxDataPresent; // FIFO has data still in it
wire rxHalfFull;    // FIFO halfway full
wire rxFull;        // FIFO is completely full. Don't write to it.
wire txDataPresent; // FIFO has data still in it
wire txHalfFull;    // FIFO halfway full
wire txFull;        // FIFO is completely full. Don't write to it.
wire tx;            // Transmit bit

integer i;
integer j;
integer enCount;

always #1 clk = ~clk;

initial begin
    clk         = 1'b0;
    rst         = 1'b1;
    txEnable    = 1'b0;
    dataIn      = 'd0;
    writeStrobe = 1'b0;
    @(posedge clk) 
    @(posedge clk) 
    rst = 1'b0;
    // Give time to send out a comma
    @(posedge txEnable)
    @(posedge txEnable)
    @(posedge txEnable)
    @(posedge txEnable)
    @(posedge txEnable)
    @(posedge txEnable)
    // Start streaming out data
    for (i=0; i<50000; i=i+1) begin
        wait(~txFull);
        @(posedge clk) dataIn <= $random(); writeStrobe = 1'b1;
        @(posedge clk) writeStrobe = 1'b0;
        @(posedge clk);
    end
end

initial begin
    readStrobe = 1'b0;
    rxEnable = 1'b1;
    enCount = CLK_RATE;
    for (j=0; j<50000; j=j+1) begin
        wait(rxDataPresent);
        @(posedge clk) readStrobe <= 1'b0;
        @(posedge clk) readStrobe <= 1'b1;
        @(posedge clk) readStrobe <= 1'b0;
        @(posedge clk) readStrobe <= 1'b0;
    end
    $stop(2);
end

always @(posedge clk) begin
    if (enCount == 0) begin
        enCount <= CLK_RATE-1;
        txEnable <= 1'b1;
    end
    else begin
        enCount <= enCount - 1;
        txEnable <= 1'b0;
    end
end


Tx8b10b #(
    .FILL_WORD_RD0(FILL_WORD_RD0),   // Send when no data present & RD=-1
    .FILL_WORD_RD1(FILL_WORD_RD1),   // Send when no data present & RD=1
    .FILL_WORD_FLIP(FILL_WORD_FLIP), // Flip status of Running Disparity when using fill word
    .LOG2_DEPTH(LOG2_DEPTH)          // log2(depth of FIFO buffer). Must be an integer.
)
generator8b10b (
    .clk(clk),                   // System clock
    .rst(rst),                   // Reset, synchronous and active high
    .en(txEnable),               // Enable strobe for transmitting
    .dataIn(dataIn),             // [7:0] Data to transmit
    .writeStrobe(writeStrobe),   // Write data to transmit FIFO
    .dataPresent(txDataPresent), // FIFO has data still in it
    .halfFull(txHalfFull),       // FIFO halfway full
    .full(txFull),               // FIFO is completely full. Don't write to it.
    .tx(tx)                      // Transmit bit
);

Rx8b10b #(
    .FILL_WORD_RD0(FILL_WORD_RD0),   ///< Send when no data present & RD=-1
    .FILL_WORD_RD1(FILL_WORD_RD1),   ///< Send when no data present & RD=1
    .FILL_WORD_FLIP(FILL_WORD_FLIP), ///< Flip status of Running Disparity when using fill word
    .CLK_RATE(CLK_RATE),             ///< Number of clocks per data bit
    .LOG2_DEPTH(LOG2_DEPTH)          ///< log2(depth of FIFO buffer). Must be an integer.
)
uut (
    .clk(clk),                   ///< System clock
    .rst(rst),                   ///< Reset, synchronous and active high
    .rxEnable(rxEnable),         ///< Set to start/enable receiver
    .rx(tx),                     ///< Receive line
    .readStrobe(readStrobe),     ///< Read data from receive FIFO
    .dataPresent(rxDataPresent), ///< FIFO has data still in it
    .halfFull(rxHalfFull),       ///< FIFO halfway full
    .full(rxFull),               ///< FIFO is completely full. Don't write to it.
    .errorDetect(errorDetect),   ///< Error detected. Does not latch.
    .dataOut(dataOut)            ///< [7:0] Data received
);


endmodule
