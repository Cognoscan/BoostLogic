/*

Simple 8n1 UART Transmiter.

Estimated Resource Usage:
Spartan 6: 23 Regs, 20 LUTs, 4 LUTRAMs

*/

///////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
///////////////////////////////////////////////////////////////////////////

module TxUart #(
    parameter LOG2_DEPTH = 4 ///< log2(depth of FIFO). Must be an integer
)
(
    // Inputs
    input clk,               ///< System clock
    input rst,               ///< Reset FIFO
    input x16BaudStrobe,     ///< Strobe at 16x baud rate
    input [7:0] dataIn,      ///< Data to transmit
    input write,             ///< Write strobe
    // Outputs
    output reg  serialOut,   ///< Serial transmit
    output wire dataPresent, ///< Data present in transmit buffer
    output wire halfFull,    ///< Transmit buffer is half full
    output wire full         ///< Transmit buffer is full
);

///////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////////

localparam SM_IDLE  =   0;
localparam SM_START =   1;
localparam SM_STOP  =   2;
localparam SM_BIT0  =   8;
localparam SM_BIT1  =   9;
localparam SM_BIT2  =  10;
localparam SM_BIT3  =  11;
localparam SM_BIT4  =  12;
localparam SM_BIT5  =  13;
localparam SM_BIT6  =  14;
localparam SM_BIT7  =  15;

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire [7:0] fifoData;

reg [7:0] data;
reg [7:0] dataInReg; // Only used if no fifo is present
reg [3:0] state;
reg [3:0] div;
reg read;
reg nextBit;
reg busy; // Only used if no fifo is present

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

if (LOG2_DEPTH > 0) begin
    Fifo #(
        .WIDTH(8),              ///< Width of data word
        .LOG2_DEPTH(LOG2_DEPTH) ///< log2(depth of FIFO). Must be an integer
    )
    txFifo (
        .clk(clk),                 ///< System clock
        .rst(rst),                 ///< Reset FIFO pointer
        .write(write),             ///< Write strobe (1 clk)
        .read(read),               ///< Read strobe (1 clk)
        .dataIn(dataIn),           ///< [7:0] Data to write
        // Outputs
        .dataOut(fifoData),        ///< [7:0] Data from FIFO
        .dataPresent(dataPresent), ///< Data is present in FIFO
        .halfFull(halfFull),       ///< FIFO is half full
        .full(full)                ///< FIFO is full
    );
end
else begin
    // Create a simple busy bit and register the data to be sent
    assign fifoData    = dataInReg;
    assign dataPresent = busy;
    assign halfFull    = busy;
    assign full        = busy;
    always @(posedge clk) begin
        if (write) begin
            dataInReg <= dataIn;
        end
        busy <= busy ? (~read & busy) : write;
    end
end

initial begin
    busy       = 1'b0;
    data       = 'd0;
    div        = 'd0;
    nextBit    = 1'b0;
    read       = 1'b0;
    serialOut  = 1'b1;
    state      = SM_IDLE;
end

// Transmit Controller
always @(posedge clk) begin
    data <= fifoData;

    // Bit / Byte output strobes
    div     <= (x16BaudStrobe) ? div + 4'd1 : div;
    nextBit <= &div & x16BaudStrobe;
    read    <= &div & x16BaudStrobe & (state == SM_BIT7);

    // Serial Output
    if ((state == SM_IDLE) || (state == SM_STOP)) begin
        serialOut <= 1'b1;
    end
    else if (state == SM_START) begin
        serialOut <= 1'b0;
    end
    else begin
        serialOut <= data[state[2:0]];
    end

    // State Machine
    if (nextBit && dataPresent) begin
        case (state)
            SM_IDLE  : state <= SM_START;
            SM_START : state <= SM_BIT0;
            SM_BIT0  : state <= SM_BIT1;
            SM_BIT1  : state <= SM_BIT2;
            SM_BIT2  : state <= SM_BIT3;
            SM_BIT3  : state <= SM_BIT4;
            SM_BIT4  : state <= SM_BIT5;
            SM_BIT5  : state <= SM_BIT6;
            SM_BIT6  : state <= SM_BIT7;
            SM_BIT7  : state <= SM_STOP;
            SM_STOP  : state <= SM_START;
            default  : state <= SM_IDLE;
        endcase
    end
    else if (nextBit) begin
        state <= SM_IDLE;
    end
end

endmodule

