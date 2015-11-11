


module Rx8b10b #(
    parameter FILL_WORD_RD0 = 10'b0011111010, ///< Send when no data present & RD=-1
    parameter FILL_WORD_RD1 = 10'b1100000101, ///< Send when no data present & RD=1
    parameter FILL_WORD_FLIP = 1'b1,          ///< Flip status of Running Disparity when using fill word
    parameter CLK_RATE = 8,                   ///< Number of clocks per data bit
    parameter LOG2_DEPTH = 4                  ///< log2(depth of FIFO buffer). Must be an integer.
)
(
    input clk,           ///< System clock
    input rst,           ///< Reset, synchronous and active high
    input rxEnable,      ///< Set to start/enable receiver
    input rx,            ///< Receive line
    input readStrobe,    ///< Read data from receive FIFO
    output dataPresent,  ///< FIFO has data still in it
    output halfFull,     ///< FIFO halfway full
    output full,         ///< FIFO is completely full. Don't write to it.
    output [7:0] dataOut ///< Data received
);

parameter integer CLK_COUNT_WIDTH = $clog2(CLK_RATE-1);
localparam CLK_COUNT_INIT = CLK_RATE-1;
localparam CLK_COUNT_CAPTURE = (CLK_RATE>>1);

reg [CLK_COUNT_WIDTH-1:0] rxClkCount;
reg [7:0] decodedData;
reg [1:10] shiftData;
reg [3:0] inCounter;
reg shiftDone;
reg locked;
reg writeStrobe;
reg rxD1;
reg rxClk;
reg error5b6b;
reg error3b4b;

if (LOG2_DEPTH > 0) begin
    Fifo #(
        .WIDTH(8),              ///< Width of data word
        .LOG2_DEPTH(LOG2_DEPTH) ///< log2(depth of FIFO). Must be an integer
    )
    txFifo
    (
        // Inputs
        .clk(clk),                 ///< System clock
        .rst(rst),                 ///< Reset FIFO pointer
        .write(writeStrobe),       ///< Write strobe (1 clk)
        .read(readStrobe),         ///< Read strobe (1 clk)
        .dataIn(decodedData),      ///< [WIDTH-1:0] Data to write
        // Outputs
        .dataOut(dataOut),         ///< [WIDTH-1:0] Data from FIFO
        .dataPresent(dataPresent), ///< Data is present in FIFO
        .halfFull(halfFull),       ///< FIFO is half full
        .full(full)                ///< FIFO is full
    );
end
else begin
    assign dataOut = decodedData;
end

initial begin
    rxD1       = 1'b0;
    rxClk      = 1'b0;
    rxClkCount = 'd0;
    shiftData  = 'd0;
    inCounter  = 'd0;
    shiftDone  = 1'b0;
    locked     = 1'b0;
end

// Bit alignment
always @(posedge clk) begin
    rxD1 <= rx;
    rxClk <= rxClkCount == CLK_COUNT_CAPTURE;
    if ((rx ^ rxD1) || (rxClkCount == 'd0)) begin
        rxClkCount <= CLK_COUNT_INIT;
    end
    else begin
        rxClkCount <= rxClkCount - 2'd1;
    end
end

// Word alignment
always @(posedge clk) begin
    // Input shift register
    if (rxClk) begin
        shiftData <= {shiftData[2:10], rxD1};
    end
    // Bit counter
    if (rxEnable && ~locked 
        && ((shiftData == FILL_WORD_RD1) || (shiftData == FILL_WORD_RD0)))
    begin
        inCounter <= 'd0;
        shiftDone <= 1'b0;
        locked    <= 1'b1;
    end
    else if (rxEnable && locked && rxClk) begin
        inCounter <= inCounter + 2'd1;
        shiftDone <= 1'b0;
    end
    else if ((inCounter == 'd10)
        && !((shiftData == FILL_WORD_RD1) || (shiftData == FILL_WORD_RD0)))
    begin
        inCounter <= 'd0;
        shiftDone <= 1'b1;
    end
    else if (inCounter == 'd10) begin
        inCounter <= 'd0;
    end
    else if (~rxEnable) begin
        inCounter <= 'd0;
        shiftDone <= 1'b0;
        locked    <= 1'b0;
    end
    else begin
        inCounter <= inCounter;
        shiftDone <= 1'b0;
    end
end

// Word Decoder
always @(posedge clk) begin
    if (rst) begin
        error5b6b <= 1'b0;
        error3b4b <= 1'b0;
        decodedData <= 'd0;
        writeStrobe <= 1'b0;
    end
    else begin
        if (shiftDone) begin
            writeStrobe <= 1'b1;
            case (shiftData[1:6])
                6'b100111 : decodedData[4:0] <= 5'b00000;
                6'b011000 : decodedData[4:0] <= 5'b00000;
                6'b011101 : decodedData[4:0] <= 5'b00001;
                6'b100010 : decodedData[4:0] <= 5'b00001;
                6'b101101 : decodedData[4:0] <= 5'b00010;
                6'b010010 : decodedData[4:0] <= 5'b00010;
                6'b110001 : decodedData[4:0] <= 5'b00011;
                6'b110001 : decodedData[4:0] <= 5'b00011;
                6'b110101 : decodedData[4:0] <= 5'b00100;
                6'b001010 : decodedData[4:0] <= 5'b00100;
                6'b101001 : decodedData[4:0] <= 5'b00101;
                6'b101001 : decodedData[4:0] <= 5'b00101;
                6'b011001 : decodedData[4:0] <= 5'b00110;
                6'b011001 : decodedData[4:0] <= 5'b00110;
                6'b111000 : decodedData[4:0] <= 5'b00111;
                6'b000111 : decodedData[4:0] <= 5'b00111;
                6'b111001 : decodedData[4:0] <= 5'b01000;
                6'b000110 : decodedData[4:0] <= 5'b01000;
                6'b100101 : decodedData[4:0] <= 5'b01001;
                6'b100101 : decodedData[4:0] <= 5'b01001;
                6'b010101 : decodedData[4:0] <= 5'b01010;
                6'b010101 : decodedData[4:0] <= 5'b01010;
                6'b110100 : decodedData[4:0] <= 5'b01011;
                6'b110100 : decodedData[4:0] <= 5'b01011;
                6'b001101 : decodedData[4:0] <= 5'b01100;
                6'b001101 : decodedData[4:0] <= 5'b01100;
                6'b101100 : decodedData[4:0] <= 5'b01101;
                6'b101100 : decodedData[4:0] <= 5'b01101;
                6'b011100 : decodedData[4:0] <= 5'b01110;
                6'b011100 : decodedData[4:0] <= 5'b01110;
                6'b010111 : decodedData[4:0] <= 5'b01111;
                6'b101000 : decodedData[4:0] <= 5'b01111;
                6'b011011 : decodedData[4:0] <= 5'b10000;
                6'b100100 : decodedData[4:0] <= 5'b10000;
                6'b100011 : decodedData[4:0] <= 5'b10001;
                6'b100011 : decodedData[4:0] <= 5'b10001;
                6'b010011 : decodedData[4:0] <= 5'b10010;
                6'b010011 : decodedData[4:0] <= 5'b10010;
                6'b110010 : decodedData[4:0] <= 5'b10011;
                6'b110010 : decodedData[4:0] <= 5'b10011;
                6'b001011 : decodedData[4:0] <= 5'b10100;
                6'b001011 : decodedData[4:0] <= 5'b10100;
                6'b101010 : decodedData[4:0] <= 5'b10101;
                6'b101010 : decodedData[4:0] <= 5'b10101;
                6'b011010 : decodedData[4:0] <= 5'b10110;
                6'b011010 : decodedData[4:0] <= 5'b10110;
                6'b111010 : decodedData[4:0] <= 5'b10111;
                6'b000101 : decodedData[4:0] <= 5'b10111;
                6'b110011 : decodedData[4:0] <= 5'b11000;
                6'b001100 : decodedData[4:0] <= 5'b11000;
                6'b100110 : decodedData[4:0] <= 5'b11001;
                6'b100110 : decodedData[4:0] <= 5'b11001;
                6'b010110 : decodedData[4:0] <= 5'b11010;
                6'b010110 : decodedData[4:0] <= 5'b11010;
                6'b110110 : decodedData[4:0] <= 5'b11011;
                6'b001001 : decodedData[4:0] <= 5'b11011;
                6'b001110 : decodedData[4:0] <= 5'b11100;
                6'b001110 : decodedData[4:0] <= 5'b11100;
                6'b101110 : decodedData[4:0] <= 5'b11101;
                6'b010001 : decodedData[4:0] <= 5'b11101;
                6'b011110 : decodedData[4:0] <= 5'b11110;
                6'b100001 : decodedData[4:0] <= 5'b11110;
                6'b101011 : decodedData[4:0] <= 5'b11111;
                6'b010100 : decodedData[4:0] <= 5'b11111;
                default   : begin decodedData[4:0] <= 5'b00000; error5b6b <= 1'b1; end
            endcase
            case (shiftData[7:10])
                4'b1011 : decodedData[7:5] <= 3'b000;
                4'b0100 : decodedData[7:5] <= 3'b000;
                4'b1001 : decodedData[7:5] <= 3'b001;
                4'b0101 : decodedData[7:5] <= 3'b010;
                4'b1100 : decodedData[7:5] <= 3'b011;
                4'b0011 : decodedData[7:5] <= 3'b011;
                4'b1101 : decodedData[7:5] <= 3'b100;
                4'b0010 : decodedData[7:5] <= 3'b100;
                4'b1010 : decodedData[7:5] <= 3'b101;
                4'b0110 : decodedData[7:5] <= 3'b110;
                4'b0111 : decodedData[7:5] <= 3'b111;
                4'b1110 : decodedData[7:5] <= 3'b111;
                4'b1000 : decodedData[7:5] <= 3'b111;
                4'b0001 : decodedData[7:5] <= 3'b111;
                default : begin decodedData[7:5] <= 3'b000; error5b6b <= 1'b1; end
            endcase
        end
        else begin
            writeStrobe <= 1'b0;
        end
    end
end

endmodule
