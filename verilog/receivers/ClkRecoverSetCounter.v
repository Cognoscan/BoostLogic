/*
Name: ClockRecoverSetCounter

Attempts to recover a clock from a serial signal whose frequency is known, set, 
and equal to system clock frequency divided by some integer. Reclocked serial 
data is then output along with a clock strobe.

Faster is pretty much always better for this type of function, so the clock 
recovery system runs at system clock.

Target frequency is set by setting the TARGET_PERIOD value such that
f_target = f_clk / TARGET_PERIOD

*/

module ClkRecoverSetCounter #(
    parameter TARGET_PERIOD = 10 ///< Expected # clks for recovered clock
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

parameter PHASE_HIGH = $clog2(TARGET_PERIOD-1) - 1;

wire intClk; ///< Internal clock

reg [PHASE_HIGH:0] phaseAccum; ///< Phase accumulator for internal clock
reg intClkD1; ///< intClk delayed 1 clk
reg rxD1;     ///< rx delayed 1 clk
reg started;  ///< Goes high once first edge found

// Debug
wire refClk;
reg isZero;
assign refClk = (phaseAccum == 'd0) && ~isZero;
always @(posedge clk) begin
    isZero <= phaseAccum == 'd0;
end

assign intClk = (phaseAccum == (TARGET_PERIOD>>1));
always @(posedge clk) begin
    rxD1 <= rx;
    intClkD1  <= intClk;
    clkStrobe <= intClk & ~intClkD1;
    rxClocked <= (intClk & ~intClkD1) ? rx : rxClocked;
end

// Phase accumulator and tracking loop
always @(posedge clk) begin
    if (rst) begin
        phaseAccum <= 'd0;
        started    <= 1'b0;
    end
    else begin
        if (started) begin
            // Phase lag - increase phase to catch up
            if ((rxD1 ^ rx) && (phaseAccum >= (TARGET_PERIOD>>1))) begin
                if (phaseAccum == TARGET_PERIOD-1) begin
                    phaseAccum <= 'd1;
                end
                else if (phaseAccum == TARGET_PERIOD-2) begin
                    phaseAccum <= 'd0;
                end
                else begin
                    phaseAccum <= phaseAccum + 2'd2;
                end
            end
            // Phase lead - don't increment phase to slow down
            else if ((rxD1 ^ rx) && (phaseAccum != 'd0)) begin
                phaseAccum <= phaseAccum;
            end
            // In phase but lagging
            else if (phaseAccum == TARGET_PERIOD-1) begin
                phaseAccum <= 'd0;
            end
            else begin
                phaseAccum <= phaseAccum + 2'd1;
            end
        end
        else begin
            started <= rxD1 ^ rx;
            phaseAccum <= 'd0;
        end
    end
end




endmodule
