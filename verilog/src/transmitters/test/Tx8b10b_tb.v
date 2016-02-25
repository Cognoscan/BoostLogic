module Tx8b10b_tb ();

reg clk;          // System clock
reg rst;          // Reset; synchronous and active high
reg en;           // Enable bit
reg [7:0] dataIn; // Data to transmit
reg writeStrobe;  // Write data to transmit FIFO

wire dataPresent; // FIFO has data still in it
wire halfFull;    // FIFO halfway full
wire full;        // FIFO is completely full. Don't write to it.
wire tx;          // Transmit bit

integer i;
integer dcOffset;

always #1 clk = ~clk;

initial begin
    dcOffset = 1'b0;
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    dataIn = 'd0;
    writeStrobe = 1'b0;
    @(posedge clk) 
    @(posedge clk) 
    rst = 1'b0;
    for (i=0; i<50000; i=i+1) begin
        wait(~full);
        @(posedge clk) dataIn <= $random(); writeStrobe = 1'b1;
        @(posedge clk) writeStrobe = 1'b0;
        @(posedge clk);
    end
    $stop(2);
end

always @(posedge clk) begin
    dcOffset <= dcOffset + $signed({tx, 1'b1});
end

Tx8b10b #(
    .FILL_WORD_RD0(10'b0011111010), // Send when no data present & RD=-1
    .FILL_WORD_RD1(10'b1100000101), // Send when no data present & RD=1
    .FILL_WORD_FLIP(1'b1),          // Flip status of Running Disparity when using fill word
    .LOG2_DEPTH(4)                  // log2(depth of FIFO buffer). Must be an integer.
)
uut (
    .clk(clk),                 // System clock
    .rst(rst),                 // Reset, synchronous and active high
    .en(en),                   // Enable strobe for transmitting
    .dataIn(dataIn),           // [7:0] Data to transmit
    .writeStrobe(writeStrobe), // Write data to transmit FIFO
    .dataPresent(dataPresent), // FIFO has data still in it
    .halfFull(halfFull),       // FIFO halfway full
    .full(full),               // FIFO is completely full. Don't write to it.
    .tx(tx)                    // Transmit bit
);

endmodule
