module BarGraph_tb ();


parameter IN_WIDTH  = 8;  ///< Input data
parameter OUT_WIDTH = 8;  ///< Number of elements in bar display
parameter LSB       = 0;  ///< LSB of data word to look at (usually 0)

reg                 clk;  ///< System clock
reg                 rst;  ///< System reset - active high & synchronous
reg                 en;   ///< Strobe for input data to update bar display
reg [IN_WIDTH-1:0]  data; ///< Input data word (binary; unsigned)

wire [OUT_WIDTH-1:0] bar; ///< Output to LED bar

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    data = 'd0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
end

always #1 clk = ~clk;

always @(posedge clk) begin
    if (rst) data <= 'd0;
    else     data <= data + 2'd1;
end

BarGraph #(
    .IN_WIDTH  (IN_WIDTH ), ///< Input data
    .OUT_WIDTH (OUT_WIDTH), ///< Number of elements in bar display
    .LSB       (LSB      )  ///< LSB of data word to look at (usually 0)
)
uut (
    .clk(clk),   ///< System clock
    .rst(rst),   ///< System reset - active high & synchronous
    .en(en),     ///< Strobe for input data to update bar display
    .data(data), ///< [IN_WIDTH-1:0] Input data word (binary, unsigned)
    .bar(bar)    ///< [OUT_WIDTH-1:0] Output to LED bar
);

endmodule
