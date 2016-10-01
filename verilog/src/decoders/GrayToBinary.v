/**
# GrayToBinary #

Decodes gray-coded data back to normal binary data. The WIDTH parameter sets the 
data bus width. The input data can be of any width up to WIDTH bits. If right 
aligned, unused bits will stay at 0. If left-aligned, unused bits will be set to 
match the LSB of the input data.

## Gray Coding ##

Invented by Frank Gray, Gray coding is a method of encoding binary data such 
that adjacent values differ in their encoding by one bit. For instance, the 
change from 1 to 2 in binary (01 -> 10) involves changing two bits, but a gray 
code would represent 1 as 01 and 2 as 11, ensuring only a single bit changes.

There are a variety of codes that satisfy these properties, but this module 
focuses on the earliest and most common. The encoding for it is very simple: XOR 
the input data with the input data shifted right by one bit (see the testbench 
for an example). The decoding process is more complex, but can be executed with 
a sequence of XOR operations, taking ceil(log2(N)) operations, where N is the 
number of bits.

*/


module GrayToBinary #(
    parameter WIDTH = 32 ///< Data width
)
(
    // Inputs
    input                  clk,       ///< System clock
    input                  rst,       ///< System reset, active high & synchronous
    input                  inStrobe,  ///< Data input strobe
    input      [WIDTH-1:0] dataIn,    ///< Gray-coded data
    // Outputs
    output reg             outStrobe, ///< Data output strobe
    output reg [WIDTH-1:0] dataOut    ///< Binary data
);

parameter SHIFT_NUM = $clog2(WIDTH);

reg [WIDTH-1:0] shiftProducts [SHIFT_NUM-1:0];

integer i;

always @(*) begin
    shiftProducts[0] = dataIn ^ (dataIn >> (1 << (SHIFT_NUM-1)));
    for (i=1; i<SHIFT_NUM; i=i+1) begin
        shiftProducts[i] = shiftProducts[i-1] 
                         ^ (shiftProducts[i-1] >> (1 << (SHIFT_NUM-1-i)));
    end
end

always @(posedge clk) begin
    if (rst) begin
        outStrobe <= 1'b0;
        dataOut   <= 'd0;
    end
    else begin
        outStrobe <= inStrobe;
        if (inStrobe) begin
            dataOut <= shiftProducts[SHIFT_NUM-1];
        end
    end
end

endmodule

