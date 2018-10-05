module ClkRecoverSetFreq #(
    parameter TARGET_FREQ = 4,
    parameter PHASE_WIDTH = 16
)
(
    // Inputs
    input clk,        ///< System clock
    input rst,        ///< Reset, synchronous and active high
    input rx,         ///< Input serial signal
    // Outputs
    output reg clkStrobe, ///< Recovered clock strobe
    output reg rxClocked  ///< Synchronized rx data
);

wire intClk;

reg [PHASE_WIDTH-1:0] phase;
reg [PHASE_WIDTH-1:0] freqErrIn;
reg [PHASE_WIDTH-1:0] freqErr;
reg rxD1;
reg intClkD1;

assign intClk = phase[PHASE_WIDTH-1];

always @(posedge clk) begin
    rxD1      <= rx;
    intClkD1  <= intClk;
    clkStrobe <=  intClk & ~intClkD1;
    rxClocked <= (intClk & ~intClkD1) ? rx : rxClocked;
end

always @(posedge clk) begin
    if (rst) begin
        phase <= 'd0;
    end
    else begin
        phase <= phase + TARGET_FREQ + freqErr;
        freqErr <= freqErr + freqErrIn;
        if (rx ^ rxD1) begin
            freqErrIn <= $signed(phase) >>> 1;
        end
    end
end

endmodule
