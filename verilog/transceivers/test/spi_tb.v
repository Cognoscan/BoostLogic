module spi_tb ();

wire nCs;
wire mosi;
wire miso;
wire sck;
wire [7:0] doutMaster;
wire [7:0] doutSlave;
wire txDataPresentM;
wire txHalfFullM;   
wire txFullM;       
wire rxDataPresentM;
wire rxHalfFullM;   
wire rxFullM;       
wire txDataPresentS;
wire txHalfFullS;   
wire txFullS;       
wire rxDataPresentS;
wire rxHalfFullS;   
wire rxFullS;       

reg clk;
reg rst;
reg spiStrobe;
reg readMaster;
reg readSlave;
reg writeMaster;
reg writeSlave;
reg cpol;
reg cpha;
reg [7:0] dinMaster;
reg [7:0] dinSlave;

parameter LOG2_DEPTH = 4;

always #1 clk = ~clk;
always begin
    @(posedge clk) spiStrobe <= 1'b1;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
    @(posedge clk) spiStrobe <= 1'b0;
end

integer i,j;

initial begin
    clk         = 1'b0;
    rst         = 1'b1;
    spiStrobe   = 1'b0;
    dinMaster   = 'd0;
    writeMaster = 1'b0;
    readMaster  = 1'b0;
    cpol        = 1'b0;
    cpha        = 1'b0;
    #7 rst = 1'b0;

    for (i=0; i<256; i=i+1) begin
        wait(~txFullM);
        wait(nCs);
        dinMaster = i;
        @(posedge clk) writeMaster = 1'b1;
        @(posedge clk) writeMaster = 1'b0;
        @(posedge clk) writeMaster = 1'b0;
    end
end

initial begin
    dinSlave   = 255;
    writeSlave = 1'b0;
    readSlave  = 1'b0;

    wait(~rst);
    wait(~nCs);
    for (j=254; j>=0; j=j-1) begin
        wait(~txFullS);
        @(posedge clk) dinSlave = j;
        @(posedge clk) writeSlave = 1'b1;
        @(posedge clk) writeSlave = 1'b0;
        @(posedge clk) writeSlave = 1'b0;
    end
end

always begin
    wait(rxDataPresentM);
    @(posedge clk) readMaster = 1'b1;
    @(posedge clk) readMaster = 1'b0;
    wait(~rxDataPresentM);
end

always begin
    wait(rxDataPresentS);
    @(posedge clk) readSlave = 1'b1;
    @(posedge clk) readSlave = 1'b0;
    wait(~rxDataPresentS);
end

XcvrSpiMaster #(
    .LOG2_DEPTH(LOG2_DEPTH)
)
uut (
    // INPUTS
    .clk(clk),                     ///< System Clock
    .rst(rst),                     ///< Reset, synchronous and active high
    .spiStrobe(spiStrobe),         ///< Strobe at SPI data rate
    // Data Interface Inputs
    .dataIn(dinMaster),            ///< [7:0] Data to send
    .write(writeMaster),           ///< Strobe to write to TX FIFO
    .read(readMaster),             ///< Strove to read from RX FIFO
    .cpol(cpol),                   ///< SPI data polarity
    .cpha(cpha),                   ///< SPI clock phase
    // SPI Signals
    .miso(miso),                   ///< Master in, slave out
    .mosi(mosi),                   ///< Master out, slave in
    .sck(sck),                     ///< SPI clock
    .nCs(nCs),                     ///< ~Chip select
    // FIFO Status
    .txDataPresent(txDataPresentM), ///< When high, interface is busy
    .txHalfFull(txHalfFullM),       ///< TX FIFO is getting full
    .txFull(txFullM),               ///< TX FIFO is full
    .rxDataPresent(rxDataPresentM), ///< RX FIFO has data available
    .rxHalfFull(rxHalfFullM),       ///< RX FIFO is getting full
    .rxFull(rxFullM),               ///< RX FIFO is full
    // Data Interface Outputs
    .dataOut(doutMaster)           ///< [7:0] Data received
);

XcvrSpiSlave #(
    .LOG2_DEPTH(LOG2_DEPTH)
)
uutSlave (
    // INPUTS
    .clk(clk),                      ///< System Clock
    .rst(rst),                      ///< Reset, synchronous and active high
    // Data Interface Inputs
    .dataIn(dinSlave),              ///< [7:0] Data to send
    .write(writeSlave),             ///< Strobe to write to TX FIFO
    .read(readSlave),               ///< Strove to read from RX FIFO
    .cpol(cpol),                    ///< SPI data polarity
    .cpha(cpha),                    ///< SPI clock phase
    // SPI Signals
    .nCs(nCs),                      ///< ~Chip select
    .sck(sck),                      ///< SPI clock
    .miso(miso),                    ///< Master in, slave out
    .mosi(mosi),                    ///< Master out, slave in
    // FIFO Status
    .txDataPresent(txDataPresentS), ///< When high, interface has data to send back
    .txHalfFull(txHalfFullS),       ///< TX FIFO is getting full
    .txFull(txFullS),               ///< TX FIFO is full
    .rxDataPresent(rxDataPresentS), ///< RX FIFO has data available
    .rxHalfFull(rxHalfFullS),       ///< RX FIFO is getting full
    .rxFull(rxFullS),               ///< RX FIFO is full
    // Data Interface Outputs
    .dataOut(doutSlave)             ///< [7:0] Data received
);

endmodule
