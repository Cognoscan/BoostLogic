module SmallSerDes #(
   parameter BYPASS_GCLK_FF        = "FALSE",        // TRUE, FALSE
   parameter DATA_RATE_OQ          = "DDR",          // SDR, DDR      | Data Rate setting
   parameter DATA_RATE_OT          = "DDR",          // SDR, DDR, BUF | Tristate Rate setting.
   parameter integer DATA_WIDTH    = 2,              // {1..8}
   parameter OUTPUT_MODE           = "SINGLE_ENDED", // SINGLE_ENDED, DIFFERENTIAL
   parameter SERDES_MODE           = "NONE",         // NONE, MASTER, SLAVE
   parameter integer TRAIN_PATTERN = 0               // {0..15}
)
(
  input  wire CLK0,
  input  wire CLK1,
  input  wire CLKDIV,
  input  wire D1,
  input  wire D2,
  input  wire D3,
  input  wire D4,
  input  wire IOCE,
  input  wire OCE,
  input  wire RST,
  input  wire SHIFTIN1,
  input  wire SHIFTIN2,
  input  wire SHIFTIN3,
  input  wire SHIFTIN4,
  input  wire T1,
  input  wire T2,
  input  wire T3,
  input  wire T4,
  input  wire TCE,
  input  wire TRAIN,
  output wire OQ,
  output wire SHIFTOUT1,
  output wire SHIFTOUT2,
  output wire SHIFTOUT3,
  output wire SHIFTOUT4,
  output wire TQ 
);

OSERDES2 #(
   .BYPASS_GCLK_FF(BYPASS_GCLK_FF), // TRUE, FALSE
   .DATA_RATE_OQ  (DATA_RATE_OQ  ), // SDR, DDR      | Data Rate setting
   .DATA_RATE_OT  (DATA_RATE_OT  ), // SDR, DDR, BUF | Tristate Rate setting.
   .DATA_WIDTH    (DATA_WIDTH    ), // {1..8}
   .OUTPUT_MODE   (OUTPUT_MODE   ), // SINGLE_ENDED, DIFFERENTIAL
   .SERDES_MODE   (SERDES_MODE   ), // NONE, MASTER, SLAVE
   .TRAIN_PATTERN (TRAIN_PATTERN )  // {0..15}
)
serdes0 (
  .OQ(OQ),
  .SHIFTOUT1(SHIFTOUT1),
  .SHIFTOUT2(SHIFTOUT2),
  .SHIFTOUT3(SHIFTOUT3),
  .SHIFTOUT4(SHIFTOUT4),
  .TQ(TQ),
  .CLK0(CLK0),
  .CLK1(CLK1),
  .CLKDIV(CLKDIV),
  .D1(D1),
  .D2(D2),
  .D3(D3),
  .D4(D4),
  .IOCE(IOCE),
  .OCE(OCE),
  .RST(RST),
  .SHIFTIN1(SHIFTIN1),
  .SHIFTIN2(SHIFTIN2),
  .SHIFTIN3(SHIFTIN3),
  .SHIFTIN4(SHIFTIN4),
  .T1(T1),
  .T2(T2),
  .T3(T3),
  .T4(T4),
  .TCE(TCE),
  .TRAIN(TRAIN)
);

endmodule
