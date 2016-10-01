module GrayToBinary_tb ();

//////////////////////////////////////////////////////////////////////////////
// Module Parameters & Signals
//////////////////////////////////////////////////////////////////////////////

parameter WIDTH       = 32;
// Inputs
reg              clk;       ///< System clock
reg              rst;       ///< System reset, active high & synchronous
reg              inStrobe;  ///< Data input strobe
reg  [WIDTH-1:0] dataIn;    ///< Gray-coded data
// Outputs
wire             outStrobe; ///< Data output strobe
wire [WIDTH-1:0] dataOut;   ///< Binary data

//////////////////////////////////////////////////////////////////////////////
// Testbench Parameters & Signals
//////////////////////////////////////////////////////////////////////////////

reg [WIDTH-1:0] gray;
reg [WIDTH-1:0] binaryActual;
reg [WIDTH-1:0] binaryTest;
reg pass;

integer numBits; // Number of bits in input word. May be different from WIDTH
integer i;
integer seed = 1245;

//////////////////////////////////////////////////////////////////////////////
// Functions & Tasks
//////////////////////////////////////////////////////////////////////////////

function [WIDTH-1:0] GrayEncode (
    input [WIDTH-1:0] binary
);
begin
    GrayEncode = binary ^ (binary >> 1);
end
endfunction

task TestGrayCode (
    input [WIDTH-1:0] grayIn,
    output [WIDTH-1:0] binaryOut
);
begin
    @(posedge clk)
    inStrobe = 1'b1;
    dataIn = grayIn;
    @(posedge clk)
    inStrobe = 1'b0;
    wait(outStrobe)
    binaryOut = dataOut;
end
endtask

//////////////////////////////////////////////////////////////////////////////
// Main Code
//////////////////////////////////////////////////////////////////////////////

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    inStrobe = 1'b0;
    dataIn = 'd0;
    pass = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;

    // Test with random vector set
    for (i=0; i<2**10; i=i+1) begin
        binaryActual = $random();
        numBits = $dist_uniform(seed, 3, WIDTH);
        // Zero out unused bits
        binaryActual = binaryActual >> (WIDTH-numBits);
        gray = GrayEncode(binaryActual);
        // Clear out unused bits
        gray = gray << (WIDTH-numBits);
        gray = gray >> (WIDTH-numBits);
        TestGrayCode(gray, binaryTest);
        if (binaryTest != binaryActual) begin
            $display("FAIL: Actual = %08h, UUT = %08h", binaryActual, binaryTest);
            pass = 1'b0;
        end
    end
    
    if (pass) begin
        $display("PASS");
    end
    else begin
        $display("FAIL");
    end
    $stop();
end

//////////////////////////////////////////////////////////////////////////////
// Unit Under Test
//////////////////////////////////////////////////////////////////////////////

GrayToBinary #(
    .WIDTH(WIDTH) ///< Data width
)
uut (
    // Inputs
    .clk(clk),             ///< System clock
    .rst(rst),             ///< System reset, active high & synchronous
    .inStrobe(inStrobe),   ///< Data input strobe
    .dataIn(dataIn),       ///< [WIDTH-1:0] Gray-coded data
    // Outputs
    .outStrobe(outStrobe), ///< Data output strobe
    .dataOut(dataOut)      ///< [WIDTH-1:0] Binary data
);

endmodule
