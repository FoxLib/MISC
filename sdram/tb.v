`timescale 10ns / 1ns
module tb;

// -----------------------------------------------------------------------------
reg clock;      always #0.5 clock    = ~clock;
reg clock_25;   always #1.0 clock_50 = ~clock_50;
reg clock_50;   always #2.0 clock_25 = ~clock_25;
reg reset_n;
// -----------------------------------------------------------------------------
initial begin clock = 1; clock_25 = 0; clock_50 = 0; reset_n = 0; #2 reset_n = 1'b1; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// -----------------------------------------------------------------------------

wire        locked = 1'b1;
wire        dram_clk;
wire [ 1:0] dram_ba;
wire [12:0] dram_addr;
wire [15:0] dram_dq;
wire        dram_cas;
wire        dram_ras;
wire        dram_we;
wire        dram_ldqm;
wire        dram_udqm;

reg  [25:0] address = 16'hA234;
reg  [ 7:0] in      = 8'h55;
wire [ 7:0] out;
wire        ready;
reg         we      = 1'b0;

always @(posedge clock_25)
if (ready) begin address <= address + 1; in <= in + 1; end

sdram M1
(
    .clock      (clock),
    .reset_n    (reset_n),
    .noinit     (1'b1),
    
    .address    (address),
    .in         (in),
    .out        (out),
    .we         (we),
    .ready      (ready),
    
    // Взаимодействие с SDRAM
    .dram_clk   (dram_clk),
    .dram_ba    (dram_ba),
    .dram_addr  (dram_addr),
    .dram_dq    (dram_dq),
    .dram_cas   (dram_cas),
    .dram_ras   (dram_ras),
    .dram_we    (dram_we),
    .dram_ldqm  (dram_ldqm),
    .dram_udqm  (dram_udqm)
);

endmodule
