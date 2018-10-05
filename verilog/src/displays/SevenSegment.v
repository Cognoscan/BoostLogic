/*
# Seven-Segment Display Decoder #

Decodes a single 4-bit word into the LED set to display it on a seven-segment 
display. The display format is below:

```
 --6--
|     |
1     5
|     |
 --0--
|     |
2     4
|     |
 --3--
```

*/

module SevenSegment (
    input wire [3:0] data,
    output reg [6:0] display
);

always @(data) begin
    case (data)
        4'h0    : display <= 7'b1111110;
        4'h1    : display <= 7'b0110000;
        4'h2    : display <= 7'b1101101;
        4'h3    : display <= 7'b1111001;
        4'h4    : display <= 7'b0110011;
        4'h5    : display <= 7'b1011011;
        4'h6    : display <= 7'b1011111;
        4'h7    : display <= 7'b1110000;
        4'h8    : display <= 7'b1111111;
        4'h9    : display <= 7'b1111011;
        4'hA    : display <= 7'b1110111;
        4'hB    : display <= 7'b0011111;
        4'hC    : display <= 7'b1001110;
        4'hD    : display <= 7'b0111101;
        4'hE    : display <= 7'b1001111;
        4'hF    : display <= 7'b1000111;
        default : display <= 7'b1111110;
    endcase
end

endmodule
