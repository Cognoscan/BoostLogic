
module Tx8b10b #(
    parameter FILL_WORD_RD0 = 10'b0011111010, // Send when no data present & RD=-1
    parameter FILL_WORD_RD1 = 10'b1100000101, // Send when no data present & RD=1
    parameter FILL_WORD_FLIP = 1'b1,          // Flip status of Running Disparity when using fill word
    parameter LOG2_DEPTH = 4                  // log2(depth of FIFO buffer). Must be an integer.
)
(
    input clk,          // System clock
    input rst,          // Reset, synchronous and active high
    input en,           // Enable strobe for transmitting
    input [7:0] dataIn, // Data to transmit
    input writeStrobe,  // Write data to transmit FIFO
    output dataPresent, // FIFO has data still in it
    output halfFull,    // FIFO halfway full
    output full,        // FIFO is completely full. Don't write to it.
    output tx           // Transmit bit
);

wire [7:0] dataToEncode;

reg [3:0] outCounter;
reg [1:9] shiftOut;
reg readStrobe;
reg runDisparity6b; // 1=RD is +1, 0=RD is -1
reg runDisparity4b; // 1=RD is +1, 0=RD is -1
reg useAlt;
reg dataPresentLatch;
reg busy; // Only used when no FIFO is present

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
        .dataIn(dataIn),           ///< [WIDTH-1:0] Data to write
        // Outputs
        .dataOut(dataToEncode),    ///< [WIDTH-1:0] Data from FIFO
        .dataPresent(dataPresent), ///< Data is present in FIFO
        .halfFull(halfFull),       ///< FIFO is half full
        .full(full)                ///< FIFO is full
    );
end
else begin
    assign dataToEncode = dataIn;
    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
        end
        else begin
            busy <= busy ? (~readStrobe & busy) : writeStrobe;
        end
    end
end

assign tx = shiftOut[1];

initial begin
    busy             = 1'b0;
    runDisparity6b   = 1'b0;
    runDisparity4b   = 1'b0;
    outCounter       = 'd0;
    shiftOut         = 'd0;
    useAlt           = 1'b0;
    dataPresentLatch = 1'b0;
end

always @(posedge clk) begin
    if (rst) begin
        runDisparity6b   <= 1'b0;
        runDisparity4b   <= 1'b0;
        outCounter       <= 'd0;
        shiftOut         <= 'd0;
        useAlt           <= 1'b0;
        dataPresentLatch <= 1'b0;
    end
    else if (en) begin
        if (outCounter == 'd0) begin
            readStrobe <= 1'b0;
            outCounter <= 'd9;
            shiftOut[7:9] <= {shiftOut[8:9], 1'b0};
            // 5b/6b Encoder
            useAlt <= 1'b0;
            dataPresentLatch <= dataPresent;
            if (dataPresent) begin
                case ({dataToEncode[4:0], runDisparity6b})
                    6'b000000 : begin shiftOut[1:6] <= 6'b100111; runDisparity4b <= 1'b1; end
                    6'b000001 : begin shiftOut[1:6] <= 6'b011000; runDisparity4b <= 1'b0; end
                    6'b000010 : begin shiftOut[1:6] <= 6'b011101; runDisparity4b <= 1'b1; end
                    6'b000011 : begin shiftOut[1:6] <= 6'b100010; runDisparity4b <= 1'b0; end
                    6'b000100 : begin shiftOut[1:6] <= 6'b101101; runDisparity4b <= 1'b1; end
                    6'b000101 : begin shiftOut[1:6] <= 6'b010010; runDisparity4b <= 1'b0; end
                    6'b000110 : begin shiftOut[1:6] <= 6'b110001; runDisparity4b <= 1'b0; end
                    6'b000111 : begin shiftOut[1:6] <= 6'b110001; runDisparity4b <= 1'b1; end
                    6'b001000 : begin shiftOut[1:6] <= 6'b110101; runDisparity4b <= 1'b1; end
                    6'b001001 : begin shiftOut[1:6] <= 6'b001010; runDisparity4b <= 1'b0; end
                    6'b001010 : begin shiftOut[1:6] <= 6'b101001; runDisparity4b <= 1'b0; end
                    6'b001011 : begin shiftOut[1:6] <= 6'b101001; runDisparity4b <= 1'b1; end
                    6'b001100 : begin shiftOut[1:6] <= 6'b011001; runDisparity4b <= 1'b0; end
                    6'b001101 : begin shiftOut[1:6] <= 6'b011001; runDisparity4b <= 1'b1; end
                    6'b001110 : begin shiftOut[1:6] <= 6'b111000; runDisparity4b <= 1'b0; end
                    6'b001111 : begin shiftOut[1:6] <= 6'b000111; runDisparity4b <= 1'b1; end
                    6'b010000 : begin shiftOut[1:6] <= 6'b111001; runDisparity4b <= 1'b1; end
                    6'b010001 : begin shiftOut[1:6] <= 6'b000110; runDisparity4b <= 1'b0; end
                    6'b010010 : begin shiftOut[1:6] <= 6'b100101; runDisparity4b <= 1'b0; end
                    6'b010011 : begin shiftOut[1:6] <= 6'b100101; runDisparity4b <= 1'b1; end
                    6'b010100 : begin shiftOut[1:6] <= 6'b010101; runDisparity4b <= 1'b0; end
                    6'b010101 : begin shiftOut[1:6] <= 6'b010101; runDisparity4b <= 1'b1; end
                    6'b010110 : begin shiftOut[1:6] <= 6'b110100; runDisparity4b <= 1'b0; end
                    6'b010111 : begin shiftOut[1:6] <= 6'b110100; runDisparity4b <= 1'b1; useAlt <= 1'b1; end
                    6'b011000 : begin shiftOut[1:6] <= 6'b001101; runDisparity4b <= 1'b0; end
                    6'b011001 : begin shiftOut[1:6] <= 6'b001101; runDisparity4b <= 1'b1; end
                    6'b011010 : begin shiftOut[1:6] <= 6'b101100; runDisparity4b <= 1'b0; end
                    6'b011011 : begin shiftOut[1:6] <= 6'b101100; runDisparity4b <= 1'b1; useAlt <= 1'b1; end
                    6'b011100 : begin shiftOut[1:6] <= 6'b011100; runDisparity4b <= 1'b0; end
                    6'b011101 : begin shiftOut[1:6] <= 6'b011100; runDisparity4b <= 1'b1; useAlt <= 1'b1; end
                    6'b011110 : begin shiftOut[1:6] <= 6'b010111; runDisparity4b <= 1'b1; end
                    6'b011111 : begin shiftOut[1:6] <= 6'b101000; runDisparity4b <= 1'b0; end
                    6'b100000 : begin shiftOut[1:6] <= 6'b011011; runDisparity4b <= 1'b1; end
                    6'b100001 : begin shiftOut[1:6] <= 6'b100100; runDisparity4b <= 1'b0; end
                    6'b100010 : begin shiftOut[1:6] <= 6'b100011; runDisparity4b <= 1'b0; useAlt <= 1'b1; end
                    6'b100011 : begin shiftOut[1:6] <= 6'b100011; runDisparity4b <= 1'b1; end
                    6'b100100 : begin shiftOut[1:6] <= 6'b010011; runDisparity4b <= 1'b0; useAlt <= 1'b1; end
                    6'b100101 : begin shiftOut[1:6] <= 6'b010011; runDisparity4b <= 1'b1; end
                    6'b100110 : begin shiftOut[1:6] <= 6'b110010; runDisparity4b <= 1'b0; end
                    6'b100111 : begin shiftOut[1:6] <= 6'b110010; runDisparity4b <= 1'b1; end
                    6'b101000 : begin shiftOut[1:6] <= 6'b001011; runDisparity4b <= 1'b0; useAlt <= 1'b1; end
                    6'b101001 : begin shiftOut[1:6] <= 6'b001011; runDisparity4b <= 1'b1; end
                    6'b101010 : begin shiftOut[1:6] <= 6'b101010; runDisparity4b <= 1'b0; end
                    6'b101011 : begin shiftOut[1:6] <= 6'b101010; runDisparity4b <= 1'b1; end
                    6'b101100 : begin shiftOut[1:6] <= 6'b011010; runDisparity4b <= 1'b0; end
                    6'b101101 : begin shiftOut[1:6] <= 6'b011010; runDisparity4b <= 1'b1; end
                    6'b101110 : begin shiftOut[1:6] <= 6'b111010; runDisparity4b <= 1'b1; end
                    6'b101111 : begin shiftOut[1:6] <= 6'b000101; runDisparity4b <= 1'b0; end
                    6'b110000 : begin shiftOut[1:6] <= 6'b110011; runDisparity4b <= 1'b1; end
                    6'b110001 : begin shiftOut[1:6] <= 6'b001100; runDisparity4b <= 1'b0; end
                    6'b110010 : begin shiftOut[1:6] <= 6'b100110; runDisparity4b <= 1'b0; end
                    6'b110011 : begin shiftOut[1:6] <= 6'b100110; runDisparity4b <= 1'b1; end
                    6'b110100 : begin shiftOut[1:6] <= 6'b010110; runDisparity4b <= 1'b0; end
                    6'b110101 : begin shiftOut[1:6] <= 6'b010110; runDisparity4b <= 1'b1; end
                    6'b110110 : begin shiftOut[1:6] <= 6'b110110; runDisparity4b <= 1'b1; end
                    6'b110111 : begin shiftOut[1:6] <= 6'b001001; runDisparity4b <= 1'b0; end
                    6'b111000 : begin shiftOut[1:6] <= 6'b001110; runDisparity4b <= 1'b0; end
                    6'b111001 : begin shiftOut[1:6] <= 6'b001110; runDisparity4b <= 1'b1; end
                    6'b111010 : begin shiftOut[1:6] <= 6'b101110; runDisparity4b <= 1'b1; end
                    6'b111011 : begin shiftOut[1:6] <= 6'b010001; runDisparity4b <= 1'b0; end
                    6'b111100 : begin shiftOut[1:6] <= 6'b011110; runDisparity4b <= 1'b1; end
                    6'b111101 : begin shiftOut[1:6] <= 6'b100001; runDisparity4b <= 1'b0; end
                    6'b111110 : begin shiftOut[1:6] <= 6'b101011; runDisparity4b <= 1'b1; end
                    6'b111111 : begin shiftOut[1:6] <= 6'b010100; runDisparity4b <= 1'b0; end
                endcase
            end
            else begin
                shiftOut[1:6] <= (runDisparity4b) ? FILL_WORD_RD1[9:4] : FILL_WORD_RD0[9:4];
                runDisparity6b <= runDisparity4b;
            end

        end
        else if (outCounter == 'd9) begin
            outCounter <= outCounter - 2'd1;
            shiftOut[1:5] <= shiftOut[2:6];
            // 3b/4b Encoder
            if (dataPresentLatch) begin
                readStrobe <= 1'b1;
                case ({dataToEncode[7:5], runDisparity4b})
                    4'b0000 : begin shiftOut[6:9] <= 4'b1011; runDisparity6b <= 1'b1; end
                    4'b0001 : begin shiftOut[6:9] <= 4'b0100; runDisparity6b <= 1'b0; end
                    4'b0010 : begin shiftOut[6:9] <= 4'b1001; runDisparity6b <= 1'b0; end
                    4'b0011 : begin shiftOut[6:9] <= 4'b1001; runDisparity6b <= 1'b1; end
                    4'b0100 : begin shiftOut[6:9] <= 4'b0101; runDisparity6b <= 1'b0; end
                    4'b0101 : begin shiftOut[6:9] <= 4'b0101; runDisparity6b <= 1'b1; end
                    4'b0110 : begin shiftOut[6:9] <= 4'b1100; runDisparity6b <= 1'b0; end
                    4'b0111 : begin shiftOut[6:9] <= 4'b0011; runDisparity6b <= 1'b1; end
                    4'b1000 : begin shiftOut[6:9] <= 4'b1101; runDisparity6b <= 1'b1; end
                    4'b1001 : begin shiftOut[6:9] <= 4'b0010; runDisparity6b <= 1'b0; end
                    4'b1010 : begin shiftOut[6:9] <= 4'b1010; runDisparity6b <= 1'b0; end
                    4'b1011 : begin shiftOut[6:9] <= 4'b1010; runDisparity6b <= 1'b1; end
                    4'b1100 : begin shiftOut[6:9] <= 4'b0110; runDisparity6b <= 1'b0; end
                    4'b1101 : begin shiftOut[6:9] <= 4'b0110; runDisparity6b <= 1'b1; end
                    4'b1110 : begin shiftOut[6:9] <= (useAlt) ? 4'b0111 : 4'b1110; runDisparity6b <= 1'b1; end
                    4'b1111 : begin shiftOut[6:9] <= (useAlt) ? 4'b1000 : 4'b0001; runDisparity6b <= 1'b0; end
                endcase
            end
            else begin
                readStrobe <= 1'b0;
                shiftOut[6:9] <= (runDisparity4b) ? FILL_WORD_RD1[3:0] : FILL_WORD_RD0[3:0];
                runDisparity4b <= FILL_WORD_FLIP ^ runDisparity6b;
            end
        end
        else begin
            readStrobe <= 1'b0;
            outCounter <= outCounter - 2'd1;
            shiftOut <= {shiftOut[2:9], 1'b0};
        end
    end
    else begin
        readStrobe <= 1'b0;
    end
end

endmodule
