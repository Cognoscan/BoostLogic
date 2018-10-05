/**
# XcvrSpi #
Simple SPI transceiver with FIFOs. 8 bit interface, but continously clocks out 
data. CS stays asserted until TX FIFO is empty.

*/

///////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
///////////////////////////////////////////////////////////////////////////

module XcvrSpiMaster #(
    parameter LOG2_DEPTH = 4
)
(
    // INPUTS
    input  clk,                ///< System Clock
    input  rst,                ///< Reset, synchronous and active high
    input  spiStrobe,          ///< Strobe at SPI data rate
    // Data Interface Inputs
    input  [7:0] dataIn,       ///< Data to send
    input  write,              ///< Strobe to write to TX FIFO
    input  read,               ///< Strove to read from RX FIFO
    input  cpol,               ///< SPI data polarity
    input  cpha,               ///< SPI clock phase
    // SPI Signals
    input  miso,               ///< Master in, slave out
    output wire mosi,          ///< Master out, slave in
    output wire sck,           ///< SPI clock
    output reg  nCs,           ///< ~Chip select
    // FIFO Status
    output wire txDataPresent, ///< When high, interface is busy
    output wire txHalfFull,    ///< TX FIFO is getting full
    output wire txFull,        ///< TX FIFO is full
    output wire rxDataPresent, ///< RX FIFO has data available
    output wire rxHalfFull,    ///< RX FIFO is getting full
    output wire rxFull,        ///< RX FIFO is full
    // Data Interface Outputs
    output wire [7:0] dataOut  ///< Data received
);

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire [7:0] txData;
wire [7:0] rxData;
wire sckInternal;

reg [7:0] dataInReg;
reg [7:0] dataOutReg;
reg [7:0] shiftReg;
reg [4:0] state;
reg busy;
reg dataOutReady;
reg misoCapture;
reg rxWrite;
reg txRead;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

// TX FIFO
if (LOG2_DEPTH > 0) begin
    Fifo #(
        .WIDTH(8),              ///< Width of data word
        .LOG2_DEPTH(LOG2_DEPTH) ///< log2(depth of FIFO). Must be an integer
    )
    txFifo (
        .clk(clk),                   ///< System clock
        .rst(rst),                   ///< Reset FIFO pointer
        .write(write),               ///< Write strobe (1 clk)
        .read(txRead),               ///< Read strobe (1 clk)
        .dataIn(dataIn),             ///< [7:0] Data to write
        // Outputs
        .dataOut(txData),            ///< [7:0] Data from FIFO
        .dataPresent(txDataPresent), ///< Data is present in FIFO
        .halfFull(txHalfFull),       ///< FIFO is half full
        .full(txFull)                ///< FIFO is full
    );
    initial begin // Set unused signals to zero.
        dataInReg = 8'd0;
        busy = 1'b0;
    end
end
else begin
    // Create a simple busy bit and register the data to be sent
    assign txData        = dataInReg;
    assign txDataPresent = busy;
    assign txHalfFull    = busy;
    assign txFull        = busy;
    always @(posedge clk) begin
        if (write) begin
            dataInReg <= dataIn;
        end
        busy <= busy ? (~txRead & busy) : write;
    end
end

// RX FIFO
if (LOG2_DEPTH > 0) begin
    Fifo #(
        .WIDTH(8),              ///< Width of data word
        .LOG2_DEPTH(LOG2_DEPTH) ///< log2(depth of FIFO). Must be an integer
    )
    rxFifo (
        .clk(clk),                   ///< System clock
        .rst(rst),                   ///< Reset FIFO pointer
        .write(rxWrite),             ///< Write strobe (1 clk)
        .read(read),                 ///< Read strobe (1 clk)
        .dataIn(rxData),             ///< [7:0] Data to write
        // Outputs
        .dataOut(dataOut),           ///< [7:0] Data from FIFO
        .dataPresent(rxDataPresent), ///< Data is present in FIFO
        .halfFull(rxHalfFull),       ///< FIFO is half full
        .full(rxFull)                ///< FIFO is full
    );
    initial begin // Set unused signals to zero.
        dataInReg = 8'd0;
        dataOutReady = 1'b0;
    end
end
else begin
    // Create a simple rxReady bit and register received data
    assign dataOut       = dataOutReg;
    assign rxDataPresent = dataOutReady;
    assign rxHalfFull    = dataOutReady;
    assign rxFull        = dataOutReady;
    always @(posedge clk) begin
        if (rxWrite) begin
            dataOutReg <= rxData;
        end
        dataOutReady <= dataOutReady ? (dataOutReady & ~read) : rxWrite;
    end
end

assign sck = (~nCs & ~state[4] & state[0]) ^ cpol; // Invert clock polarity if necessary
assign mosi = shiftReg[7]; // Master out is MSB of shift register

initial begin
        busy         = 1'b0;
        dataOutReady = 1'b0;
        dataOutReg   = 'd0;
        nCs          = 1'b1;
        state        = 'd0;
        shiftReg     = 'd0;
        txRead       = 1'b0;
        rxWrite      = 1'b0;
        misoCapture  = 1'b0;
end

// State Machine:
// The state machine acts as a 16-state counter during a transaction. The LSB is 
// used as the clock, and the 5th bit is used to set nCs. Phase of the LSB is 
// used to determine when to capture MISO and when to clock out MOSI.

assign rxData = {shiftReg[6:0], misoCapture};
assign sckInternal = ~state[4] & (state[0] ^ cpha);
always @(posedge clk) begin
    if (rst) begin
        nCs         <= 1'b1;
        state       <= 5'd17;
        shiftReg    <= 'd0;
        txRead      <= 1'b0;
        rxWrite     <= 1'b0;
        misoCapture <= 1'b0;
    end
    else begin
        if (spiStrobe) begin
            case (state)
                5'd16 : begin
                    rxWrite <= 1'b1;
                    if (txDataPresent) begin
                        txRead <= 1'b1;
                    end
                end
                default : begin
                    rxWrite <= 1'b0;
                    txRead <= 1'b0;
                end
            endcase
            if (state == 5'd17 && txDataPresent) begin
                state <= 'd0;
            end
            else if (state != 5'd17) begin
                state <= state + 2'd1;
            end
            // Chip Select
            nCs <= state[4];
            // MOSI/MISO Shift register
            if (~state[4] & state[0]) begin
                shiftReg <= {shiftReg[6:0], misoCapture};
            end
            else if (state[4]) begin
                shiftReg <= txData;
            end
            else
            begin
                shiftReg <= shiftReg;
            end
            // MISO capture
            misoCapture <= (~state[4] & ~state[0]) ? miso : misoCapture;
        end
        else begin
            rxWrite <= 1'b0;
            txRead <= 1'b0;
        end
    end
end

endmodule
