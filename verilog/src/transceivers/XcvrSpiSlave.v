/**
# XcvrSpi #
Simple SPI transceiver with FIFOs. 8 bit interface, but continously clocks out 
data. CS stays asserted until TX FIFO is empty.

*/

///////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
///////////////////////////////////////////////////////////////////////////

module XcvrSpiSlave #(
    parameter LOG2_DEPTH = 4
)
(
    // INPUTS
    input  clk,           ///< System Clock
    input  rst,           ///< Reset, synchronous and active high
    // Data Interface Inputs
    input  [7:0] dataIn,  ///< Data to send
    input  write,         ///< Strobe to write to TX FIFO
    input  read,          ///< Strove to read from RX FIFO
    input  cpol,          ///< SPI data polarity
    input  cpha,          ///< SPI clock phase
    // SPI Signals
    input  nCs,           ///< ~Chip select
    input  sck,           ///< SPI clock
    input  miso,          ///< Master in, slave out
    output mosi,          ///< Master out, slave in
    // FIFO Status
    output txDataPresent, ///< When high, interface has data to send back
    output txHalfFull,    ///< TX FIFO is getting full
    output txFull,        ///< TX FIFO is full
    output rxDataPresent, ///< RX FIFO has data available
    output rxHalfFull,    ///< RX FIFO is getting full
    output rxFull,        ///< RX FIFO is full
    // Data Interface Outputs
    output [7:0] dataOut  ///< Data received
);

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire [7:0] txData;
wire [7:0] rxData;

reg [7:0] dataInReg;
reg [7:0] dataOutReg;
reg [7:0] shiftReg;
reg [2:0] spiCount;
reg busy;
reg dataOutReady;
reg mosiCapture;
reg sckD1;
reg txRead;
reg rxWrite;

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

initial begin
    dataOutReg   = 'b0;
    dataInReg    = 'b0;
    shiftReg     = 'd0;
    spiCount     = 'd7;
    busy         = 1'b0;
    dataOutReady = 1'b0;
    mosiCapture  = 1'b0;
    sckD1        = 1'b0;
    txRead       = 1'b0;
    rxWrite      = 1'b0;
end

assign miso = shiftReg[7]; // Slave out is MSB of shift register
assign rxData = {shiftReg[6:0], mosiCapture};

always @(posedge clk) begin
    sckD1 <= sck;

    if (nCs) begin
        spiCount <= 'd7;
        shiftReg <= txData;
        txRead <= 1'b0;
        rxWrite <= 1'b0;
    end
    else if ((sck ^sckD1) && !(sck ^ cpol ^ cpha)) begin
        spiCount <= spiCount - 'd1;
        if (spiCount == 'd0) begin
            shiftReg <= txData;
            txRead <= 1'b1;
        end
        else begin
            shiftReg <= {shiftReg[6:0], mosiCapture};
            txRead <= 1'b0;
        end
    end
    else begin
        spiCount <= spiCount;
        shiftReg <= shiftReg;
        txRead   <= 1'b0;
    end

    // MISO data capture
    if ((sck ^ sckD1) && (sck ^ cpol ^ cpha)) begin
        mosiCapture <= mosi;
        if (spiCount == 'd0) begin
            rxWrite <= 1'b1;
        end
        else begin
            rxWrite <= 1'b0;
        end
    end
    else begin
        mosiCapture <= mosiCapture;
        rxWrite <= 1'b0;
    end
end

endmodule
