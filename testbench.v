`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2019 01:26:45 AM
// Design Name: 
// Module Name: testbench
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

module testbench();

reg clock, reset, temp_rh_sel, start, reset_conn, crc_off; 
wire com_error, SCK;
reg SDA_in;
wire SDA;
//wire [19:0] RH, TEMP;
wire [3:0] anode;
wire [7:0] led_code;

//pullup (SDA);

sht10_sensor dut (
    clock, 
    reset,
    temp_rh_sel,
    start,
    reset_conn,
    crc_off,
    com_error,
    SCK,
    SDA,
    anode,
    led_code
);

wire SDA_out;
assign SDA =     (dut.sda_out_en == 1'b0 ) ? SDA_in : 1'bz;  
assign SDA_out = (dut.sda_out_en == 1'b1 ) ? SDA : 1'b1;

//assign SDA =     (dut.SDA_TRI == 1'b0 ) ? SDA_in : 1'bz;  
//assign SDA_out = (dut.SDA_TRI == 1'b1 ) ? SDA : 1'b1;

always begin
    #5; clock = !clock;
end

initial begin
    clock       = 1'b0;
    reset       = 1'b0;
    temp_rh_sel = 1'b0; 
    start       = 1'b0;
    reset_conn  = 1'b0; 
    crc_off     = 1'b1;
    SDA_in      = 1'b1;
end

initial begin
    #10000; reset = 1'b1;
    #100; reset = 1'b0;
    #100;
    
    start = 1'b1;
    // CMD ACK
    wait (dut.state == 4'd5 ); SDA_in = 1'b0;
    #(1000*10);                 SDA_in = 1'b1;
    
    
    // MEASURE TIME:
    wait (dut.state == 4'd6 );  SDA_in = 1'b1; 
    #(10*1000*10);              SDA_in = 1'b0;
     
    // MSB 
    wait (dut.state == 4'd8 );  
	repeat (6) begin
		@ (negedge SCK );
		#(5000/2);
		SDA_in = 1'b1;
	end
    
    // DATA MSB ACK
    wait (dut.state == 4'd9 );  SDA_in = 1'b0;
    #(1000*10);                 SDA_in = 1'b1;
        
    // DATA LSB ACK
    wait (dut.state == 4'd10 );  
	repeat (8) begin
		@ (negedge SCK );
		#(5000/2);
		SDA_in = $random();
	end
        
end


endmodule