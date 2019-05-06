`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/29/2019 09:15:13 PM
// Design Name: 
// Module Name: seven_segs
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// refresh period = 10ms  -&gt; 1000,000 counter
// digit refresh  = 2.5ms -&gt; 1/4 period of counter
// -------------------------
// input data has 4 digits



module seven_seg (
    input   wire            clock,
    input   wire            reset,
//    input   wire            mod_cs,
    input   wire    [3:0]   dig0,
    input   wire    [3:0]   dig1,
    input   wire    [3:0]   dig2,
    input   wire    [3:0]   dig3,
    output  wire    [3:0]   anode,
    output  reg     [7:0]   led_code
);

// 10 ms count. Free run
wire anode0;
wire anode1;
wire anode2;
wire anode3;
reg     [3:0]   segment;
reg     [19:0]  period_cnt;

always @ ( posedge clock or posedge reset ) begin
    if ( reset == 1'b1 ) begin
        period_cnt  <= 20'd0;
    end
 else begin
    if ( period_cnt < 20'd1000000 )
        period_cnt <= period_cnt + 20'd1;
    else
        period_cnt <= 20'd0;
 end
end

// anode logic

assign anode0 = ((period_cnt >= 20'd0) && (period_cnt < 20'd250000 )) ? 1'b0 : 1'b1;
assign anode1 = ((period_cnt >= 20'd250000) && (period_cnt < 20'd500000  )) ? 1'b0 : 1'b1;
assign anode2 = ((period_cnt >= 20'd500000) && (period_cnt < 20'd750000  )) ? 1'b0 : 1'b1;
assign anode3 = ((period_cnt >= 20'd750000) && (period_cnt < 20'd1000000 )) ? 1'b0 : 1'b1;

// select code
assign anode = {anode3, anode2, anode1, anode0};

// value to segment
always @(*)begin
 case (anode)
  4'b1110: segment = dig0;
  4'b1101: segment = dig1;
  4'b1011: segment = dig2;
  4'b0111: segment = dig3;
  default: segment = 8'h00;
 endcase
end

// decode digit to bcd code
always @ (posedge clock or posedge reset ) begin
 if (reset == 1'b1) begin
  led_code  <= 8'h81;
 end
 else begin
  case (segment)
   4'h0:      led_code    <=   8'b10000001;
   4'h1:      led_code    <=   8'b11001111;
   4'h2:      led_code    <=   8'b10010010;
   4'h3:      led_code    <=   8'b10000110;
   4'h4:      led_code    <=   8'b11001100;
   4'h5:      led_code    <=   8'b10100100;
   4'h6:      led_code    <=   8'b10100000;
   4'h7:      led_code    <=   8'b10001111;
   4'h8:      led_code    <=   8'b10000000;
   4'h9:      led_code    <=   8'b10000100;
   4'hA:      led_code    <=   8'b10001000;
   4'hB:      led_code    <=   8'b11100000;
   4'hC:      led_code    <=   8'b10110001;
   4'hD:      led_code    <=   8'b11000010;
   4'hE:      led_code    <=   8'b10110000;
   4'hF:      led_code    <=   8'b10111000;
   default:   led_code    <=   8'h81; // 0000
  endcase
 end
end

endmodule
