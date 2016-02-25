/*
Usage: 3 slices, 13 regs, 8 LUTs, 4 LUTRAMs, for 16-deep 8-bit FIFO
*/

module Fifo #(
    parameter WIDTH      = 8, ///< Width of data word
    parameter LOG2_DEPTH = 4  ///< log2(depth of FIFO). Must be an integer
)
(
    // Inputs
    input clk,                       ///< System clock
    input rst,                       ///< Reset FIFO pointer
    input write,                     ///< Write strobe (1 clk)
    input read,                      ///< Read strobe (1 clk)
    input [WIDTH-1:0] dataIn,        ///< Data to write
    // Outputs
    output wire [WIDTH-1:0] dataOut, ///< Data from FIFO
    output reg dataPresent,          ///< Data is present in FIFO
    output wire halfFull,            ///< FIFO is half full
    output wire full                 ///< FIFO is full
);

reg [WIDTH-1:0] memory[2**LOG2_DEPTH-1:0];
reg [LOG2_DEPTH-1:0] pointer;

wire zero;

integer i;

// Zero out internal memory
initial begin
    pointer     = 'd0;
    dataPresent = 1'b0;
    for (i=0; i<(2**LOG2_DEPTH); i=i+1) begin
        memory[i] = 'd0;
    end
end

// Shift register for FIFO
always @(posedge clk) begin
    if (write) begin
        memory[0] <= dataIn;
        for (i=1; i<(2**LOG2_DEPTH); i=i+1) begin
            memory[i] <= memory[i-1];
        end
    end
end
assign dataOut = memory[pointer];

// Pointer for FIFO
always @(posedge clk) begin
    if (rst) begin
        pointer <= 'd0;
        dataPresent <= 1'b0;
    end
    else begin
        dataPresent <= write 
                     | (dataPresent & ~zero)
                     | (dataPresent &  zero & ~read);
        case ({read, write})
            2'b00 : pointer <= pointer;
            2'b01 : pointer <= (!full && dataPresent) ? pointer + 2'd1 : pointer;
            2'b10 : pointer <= (!zero)  ? pointer - 2'd1 : pointer;
            2'b11 : pointer <= pointer;
        endcase
    end
end

assign zero = ~|pointer;
assign halfFull = pointer[LOG2_DEPTH-1];  
assign full = &pointer;

endmodule
