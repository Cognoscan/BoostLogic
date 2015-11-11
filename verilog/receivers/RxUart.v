/*

Simple 8n1 UART receiver with 16-deep receive buffer.

Estimated Resource Usage:
Spartan 6: 24 Regs, 20 LUTs, 4 LUTRAMs

*/

///////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
///////////////////////////////////////////////////////////////////////////

module RxUart #(
    parameter LOG2_DEPTH = 4 ///< log2(depth of FIFO). Must be an integer
)
(
    input clk,                 ///< System clock
    input rst,                 ///< Reset FIFO
    input x16BaudStrobe,       ///< Strobe at 16x baud rate
    input read,                ///< Read strobe for buffer
    input serialIn,            ///< Serial Receive
    output wire [7:0] dataOut, ///< Data from receive buffer
    output wire dataPresent,   ///< Receive buffer not empty
    output wire halfFull,      ///< Receive buffer half full
    output wire full           ///< Receive buffer full
);

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

reg [7:0] data;
reg [7:0] dataOutReg; // Only used if no fifo is present
reg [3:0] div;
reg dataOutReady;     // Only used if no fifo is present
reg sampleStrobe;
reg sample;
reg sampleD1;
reg write;
reg run;
reg startBit;
reg stopBit;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

if (LOG2_DEPTH > 0) begin
    Fifo #(
        .WIDTH(8),              ///< Width of data word
        .LOG2_DEPTH(LOG2_DEPTH) ///< log2(depth of FIFO). Must be an integer
    )
    rxFifo (
        .clk(clk),                 ///< System clock
        .rst(rst),                 ///< Reset FIFO pointer
        .write(write),             ///< Write strobe (1 clk)
        .read(read),               ///< Read strobe (1 clk)
        .dataIn(data),           ///< [7:0] Data to write
        // Outputs
        .dataOut(dataOut),            ///< [7:0] Data from FIFO
        .dataPresent(dataPresent), ///< Data is present in FIFO
        .halfFull(halfFull),       ///< FIFO is half full
        .full(full)                ///< FIFO is full
    );
end
else begin
    // Create a simple rxReady bit and register received data
    assign dataOut     = dataOutReg;
    assign dataPresent = dataOutReady;
    assign halfFull    = dataOutReady;
    assign full        = dataOutReady;
    always @(posedge clk) begin
        if (write) begin
            dataOutReg <= data;
        end
        dataOutReady <= dataOutReady ? (dataOutReady & ~read) : write;
    end
end

initial begin
    dataOutReg   = 8'hFF;
    dataOutReady = 1'b0;
    data         = 8'hFF;
    div          = 4'd0;
    sampleStrobe = 1'b0;
    sample       = 1'b1;
    sampleD1     = 1'b1;
    write        = 1'b0;
    run          = 1'b0;
    startBit     = 1'b0;
    stopBit      = 1'b1;
end

always @(posedge clk) begin

    sampleStrobe <= x16BaudStrobe & (div[3:0] == 4'b0111);
    if (x16BaudStrobe) begin
        sample   <= serialIn;
        sampleD1 <= sample;
    end

    write <= sampleStrobe & ~data[0];
    if (sampleStrobe) begin
        {stopBit, data} <= {sample, data[7:1]};
    end

    if (run) begin
        run <= ~sampleStrobe | sampleStrobe & data[0] & (~sample | sample & ~startBit);
        startBit <= startBit & ~sampleStrobe; // Keep asserted while sampleStrobe is low
        div       <= (x16BaudStrobe) ? div + 4'd1 : div;
    end
    else begin
        run      <= ~sample & sampleD1;
        startBit <= ~sample & sampleD1; // Start is falling edge of serialIn
        div      <= 4'd0;
        stopBit  <= 1'b1;
        data     <= 8'hFF;
    end
end

endmodule
