module BarGraph #(
    parameter IN_WIDTH  = 8, ///< Input data
    parameter OUT_WIDTH = 8, ///< Number of elements in bar display
    parameter LSB       = 0  ///< LSB of data word to look at (usually 0)
)
(
    input  wire                 clk,  ///< System clock
    input  wire                 rst,  ///< System reset - active high & synchronous
    input  wire                 en,   ///< Strobe for input data to update bar display
    input  wire [IN_WIDTH-1:0]  data, ///< Input data word (binary, unsigned)
    output reg  [OUT_WIDTH-1:0] bar   ///< Output to LED bar
);

localparam OUT_RANGE = (OUT_WIDTH+LSB > IN_WIDTH) ? (IN_WIDTH-LSB) : OUT_WIDTH;

integer i;

always @(posedge clk) begin
    if (rst) begin
        bar <= 'd0;
    end
    else begin
        for (i=0; i<OUT_RANGE; i=i+1) begin
            bar[i] <= |(data >> (i+LSB));
        end
    end
end

endmodule
