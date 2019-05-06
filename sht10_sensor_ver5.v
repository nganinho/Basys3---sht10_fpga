`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2019 01:34:29 AM
// Design Name: 
// Module Name: sht10_sensor
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
`define IDLE  		     4'd0
`define CONN_RESET      4'd1
`define TRAN_START      4'd2
`define ADD_TRAN  	     4'd3
`define CMD_TRAN  	     4'd4
`define CMD_ACK  	     4'd5
`define SENS_MEA  	     4'd6
`define DATA_IDLE 	     4'd7
`define DATA_MSB  	     4'd8
`define DATA_ACK1  	     4'd9
`define DATA_LSB  	     4'd10
`define DATA_ACK2  	     4'd11
`define CHECK_SUM  	     4'd12
`define CHECK_ACK  	     4'd13
`define SLEEP  		     4'd14



// 100Mhz -> period = 10ns
// 100Khz -> period = 10000ns
// TLOW  = 5000ns --> count = 500
// THIGH = 5000ns --> count = 500
// --> 1/4 Period count = 250
// TSLEEP: 11000ns



// START:
// SCK:  HIGH - LOW - HIGH - LOW
// DATA: HIGH - LOW - HIGH
`define 	 TLOW	 	500
`define 	 THIGH   	500
`define      TCYCLE 	1000

module sht10_sensor(
    input wire clock,
    input wire reset,
    input wire temp_rh_sel, // 0: temp. 1: rh
	input wire start,
	input wire reset_conn,
	input wire crc_off,
    output wire com_error,
	//output reg [19:0] RH,
	//output reg [19:0] TEMP,
	output reg SCK,
	inout wire SDA,
	// display
    output  wire    [3:0]   anode,
    output  wire    [7:0]   led_code
    );

wire [4:0] cmd_temp;
wire [4:0] cmd_rh;
wire [2:0] add_code;
wire    get_sensor;

reg     start_, start__;
reg     data_out;

reg [3:0] state;
reg [3:0] next;
reg state_end;
//reg [3:0] state_count;
reg [3:0] state_cycle;

reg [19:0]  clk_cnt;
reg [3:0]   cyc_cnt;
reg         clk_equal;
reg         cyc_equal;
//reg         data_in;
reg         sda_out_en;

reg cmdack;
assign com_error = cmdack;

reg [13:0]  dat_temp;
reg [11:0]  dat_rh;

wire  measure_end;
reg measure_, measure__;

reg [11:0] RH;
reg [13:0] TEMP;

pullup (SDA);   

assign add_code = 3'b000;
assign cmd_temp = 5'b00011;
assign cmd_rh   = 5'b00101;
 
// get the edge of start
always @ (posedge clock or posedge reset ) begin
	if ( reset == 1'b1 ) 	begin 
		start_ 	<= 1'b0;
		start__	<= 1'b0; 
	end
	else begin 
		start_ 	<= start;
		start__ <= start_;
	end 
end 

assign get_sensor = start_ && !start__;

//inout pin
assign SDA 		= ( sda_out_en  ) ? data_out : 1'bz;
//assign data_in 	= ( !sda_out_en ) ? SDA : 1'b0;

// clk_equal
always @ (*) begin 
	case (state) 
		`TRAN_START: 	if ( clk_cnt == (3*`TLOW/2 + 2*`THIGH)) clk_equal 	= 1'b1; 
						else 								  clk_equal 	= 1'b0;
		default: 		if ( clk_cnt == `TCYCLE ) 			  clk_equal	= 1'b1;
						else 								  clk_equal 	= 1'b0;
	endcase
end

// cyc_equal
always @(*) begin
	if ( cyc_cnt == state_cycle ) 	cyc_equal 	= 1'b1;
	else 							cyc_equal	= 1'b0;
end

// IO direction control
always @ (*) begin 
	case (state) 
		`CMD_ACK,
		`SENS_MEA,
		`DATA_IDLE,
		`DATA_MSB,
		`DATA_LSB,
		`CHECK_SUM: sda_out_en = 1'b0;
		default: 	sda_out_en = 1'b1;
	endcase
end

// number of sensor cycle
always @ (*) begin 
	case (state)
		`IDLE: 			  state_cycle   =  4'd0;
		`CONN_RESET: 	  state_cycle	=  4'd8;
		`TRAN_START: 	  state_cycle	=  4'd0;
		`ADD_TRAN: 		  state_cycle	=  4'd2;
		`CMD_TRAN: 		  state_cycle	=  4'd4;
		`CMD_ACK:		  state_cycle	=  4'd0;
		`SENS_MEA:		  state_cycle   =  4'd0;        
		`DATA_IDLE:	      if (temp_rh_sel == 1'b1 )   state_cycle =  4'd3;
		                  else                        state_cycle =  4'd1;
		`DATA_MSB:        if (temp_rh_sel == 1'b1 )   state_cycle =  4'd3;
		                  else                        state_cycle =  4'd5;
		`DATA_ACK1:       state_cycle	=  4'd0;
		`DATA_LSB:        state_cycle	=  4'd7;
		`DATA_ACK2:       state_cycle	=  4'd0;
		`CHECK_SUM:       state_cycle	=  4'd7;
		`CHECK_ACK:       state_cycle	=  4'd0;
		`SLEEP:           state_cycle	=  4'd1;
	default:              state_cycle   =  4'd0;
	endcase
end

// measure_end
always @ (posedge clock or posedge reset ) begin
    if ( reset == 1'b1 ) begin
        measure_    <= 1'b1;
        measure__   <= 1'b1;
    end
    else begin
        measure_    <= SDA;
        measure__   <= measure_;
    end
end

assign measure_end = (state == `SENS_MEA ) && (!measure_ && measure__);


// cycle counter for each state.
always @ ( posedge clock or posedge reset) begin
	if ( reset == 1'b1 ) begin
		cyc_cnt 	<= 4'd0;
	end 
	else begin 
	   case (state)
	       `TRAN_START: cyc_cnt    <= 4'd0;
	       default: if (state_end == 1'b1 ) begin 
	                   if ( clk_equal )   cyc_cnt <= 4'd0;
	                   else               cyc_cnt <= cyc_cnt;
	                end
	                else begin
	                   if ( clk_equal )   cyc_cnt <= cyc_cnt + 4'd1;
	                   else               cyc_cnt <= cyc_cnt;
	                end
	   endcase
	end
end

// counter for TCYCLE
always @ ( posedge clock or posedge reset ) begin
	if ( reset == 1'b1 ) begin 
		clk_cnt 	<= 	20'd0;
	end
	else begin
	   case (state)
	       `TRAN_START,
	       `ADD_TRAN,
	       `CMD_TRAN,
	       `CMD_ACK,
	       `DATA_IDLE,
	       `DATA_MSB,
	       `DATA_ACK1,
	       `DATA_LSB,
	       `DATA_ACK2,
	       `CHECK_SUM,
	       `CHECK_ACK: if (clk_equal == 1'b1 ) clk_cnt  <= 20'd0;
	                   else                    clk_cnt  <= clk_cnt + 20'd1;
	        default:                       clk_cnt <= 20'd0;
	   endcase 
	end	
end

// state machine
always @ ( posedge clock or posedge reset ) begin
	if ( reset == 1'b1 ) state <= `IDLE;
	else 				 state <= next;
end

// next state
always @ (*) begin 
	case (state)
		`IDLE		: 	if ( get_sensor == 1'b1) begin
							if ( reset_conn == 1'b1 ) next 	= 	`CONN_RESET;
							else 					  next 	= 	`TRAN_START;
						end
						else						next 	= 	`IDLE;
		`CONN_RESET	: 	if ( state_end == 1'b1) 	next 	= 	`TRAN_START;
						else						next 	= 	`CONN_RESET;
		`TRAN_START	: 	if ( state_end == 1'b1 ) 	next 	= 	`ADD_TRAN;
						else 						next	= 	`TRAN_START;
		`ADD_TRAN	: 	if ( state_end == 1'b1 ) 	next	= 	`CMD_TRAN;
						else						next	= 	`ADD_TRAN;
		`CMD_TRAN	: 	if ( state_end == 1'b1 ) 	next	= 	`CMD_ACK;
						else 						next 	= 	`CMD_TRAN;
		`CMD_ACK	: 	if ( state_end == 1'b1 ) 	begin 
							if ( cmdack == 1'b0 ) 	next 	= 	`SENS_MEA;
							else 					next	= 	`SLEEP;
						end
						else 						next	= 	`CMD_ACK;
		`SENS_MEA   :   if ( state_end == 1'b1 )    next    =   `DATA_IDLE;
		                else                        next    =   `SENS_MEA;
		`DATA_IDLE	:  	if ( state_end == 1'b1 ) 	next 	= 	`DATA_MSB;
						else 						next 	= 	`DATA_IDLE;
		`DATA_MSB	:	if ( state_end == 1'b1 ) 	next	= 	`DATA_ACK1;
						else 						next 	= 	`DATA_MSB;
		`DATA_ACK1	: 	if ( state_end == 1'b1 ) 	next 	= 	`DATA_LSB;
						else 						next	= 	`DATA_ACK1;
		`DATA_LSB	:	if ( state_end == 1'b1 ) 	next	= 	`DATA_ACK2;
						else 						next	= 	`DATA_LSB;
		`DATA_ACK2	: 	if ( state_end == 1'b1 ) 	begin 
							if ( crc_off == 1'b1 ) 	next 	= 	`SLEEP;
							else 					next 	= 	`CHECK_SUM;
						end
						else 						next	= 	`DATA_ACK2;
		`CHECK_SUM	: 	if ( state_end == 1'b1 ) 	next 	= 	`CHECK_ACK;
						else 						next	= 	`CHECK_SUM;
		`CHECK_ACK	: 	if ( state_end == 1'b1 ) 	next	= 	`SLEEP;
						else 						next	= 	`CHECK_ACK;
		`SLEEP		:   if ( state_end == 1'b1 )    next    =   `IDLE;
						else 						next    = 	`SLEEP;
		default 	: 								next   	= 	`IDLE;
	endcase 
end 

// ack reg
always @ (posedge clock or posedge reset) begin
	if (reset == 1'b1) begin 
		cmdack <= 1'b0;
	end
	else begin 
		if (state == `CMD_ACK ) begin
			//if ( clk_cnt == `TLOW + `THIGH/2) 				cmdack <= SDA;
			if (clk_cnt == `TCYCLE/2)                       cmdack <= SDA;
		end
		else begin 
			if ( state == `CONN_RESET || state == `IDLE ) 	cmdack <= 1'b0;
		end
	end
end

// state_end
always @ (*) begin
	if ( state != `SENS_MEA ) begin 
	    if (cyc_equal && clk_equal ) 	state_end = 1'b1;
	    else 							state_end = 1'b0;
	end
	else begin
	   if ( measure_end == 1'b1 )       state_end = 1'b1;
	   else                             state_end = 1'b0;  
	end
end

// SCK 
always @ (posedge clock or posedge reset ) begin
    if (reset == 1'b1 ) begin
        SCK     <= 1'b0;
    end
    else begin
        case (state)
            `TRAN_START:  if  ((clk_cnt < `THIGH) || ((clk_cnt > `TCYCLE) && (clk_cnt < `TCYCLE + `THIGH))) SCK <=  1'b1;
                          else     SCK <=  1'b0;
            `ADD_TRAN,
			`CMD_TRAN,
			`CMD_ACK,
			`DATA_IDLE,
			`DATA_MSB,
			`DATA_ACK1,
			`DATA_LSB,
			`DATA_ACK2,
			`CHECK_SUM,
			`CHECK_ACK,
			`SLEEP: 		if (clk_cnt < `TLOW/2 || clk_cnt > (`THIGH + `TLOW/2)) 	SCK <= 1'b0;
							else 					SCK <= 1'b1;
			default: 								SCK <= 1'b0;
        endcase
    end
end


// OUTPUT data
always @ ( posedge clock or posedge reset) begin
	if (reset == 1'b1 ) begin 
	end
	else begin 
		case (state )
		    `TRAN_START: if (clk_cnt > `THIGH/2 && clk_cnt < (`TCYCLE + `THIGH/2))    data_out <= 1'b0;
		                 else                                                         data_out <= 1'b1;
		                       
			`ADD_TRAN: 								data_out 	<= 	add_code[2-cyc_cnt];
			`CMD_TRAN: 	if (temp_rh_sel == 1'b0 ) 	data_out 	<= 	cmd_temp[4-cyc_cnt];
						else 						data_out	<= 	cmd_rh[4-cyc_cnt];
			`DATA_ACK1, 
			`DATA_ACK2: 							data_out	<= 	crc_off; // ACK decide the CRC check existence.
			`CHECK_ACK: 							data_out	<= 	1'b1;
			default: 								data_out 	<= 	1'b1;
		endcase
	end
end
    
// data input from sensor
always @ ( posedge clock or posedge reset ) begin 
	if ( reset == 1'b1 ) begin 
		dat_temp 	<= 14'd0;
		dat_rh		<= 12'd0;
	end
	else begin
		if (state == `DATA_MSB ) begin 
			if ( temp_rh_sel == 1'b1 ) 	begin
			     if (clk_cnt == 3*`THIGH/2)      dat_rh[11-cyc_cnt] 	  <= SDA;
			end
			else begin
			     if (clk_cnt == 3*`THIGH/2)      dat_temp[13-cyc_cnt] 	  <= SDA;
			end
		end
		else begin
			if (state == `DATA_LSB ) begin
			   if (clk_cnt == 3*`THIGH/2) begin
				if ( temp_rh_sel == 1'b1 ) 	dat_rh[7-cyc_cnt] 	<= SDA;
				else 						dat_temp[7-cyc_cnt]	<= SDA;
		     end
			end
		end
	end
end	

// calculation RH
// RH = c1 + c2*SOrh  + c3 * SOrh
//SORH 		c1 		c2 		c3
//12 bit 	-2.0468 0.0367 	-1.5955E-6
//	8 bit 	-2.0468 0.5872 	-4.0845E-4

// TEMP
// T = d1 + d2 * SOtemp;
//VDD 	d1 (°C) d1 (°F) 	SOT 		d2 (°C) d2 (°F)
//5V 	-40.1 	-40.2 		14bit 		0.01 	0.018
//4V 	-39.8 	-39.6 		12bit 		0.04 	0.072
//3.5V 	-39.7 	-39.5
//3V 	-39.6 	-39.3
//2.5V 	-39.4 	-38.9
always @ (posedge clock or posedge reset ) begin
	if (reset == 1'b1 ) begin 
		RH		<= 12'd0;
		TEMP	<= 14'd0;
	end
	else begin
		if (state == `DATA_ACK2 && state_end ) begin
			if ( temp_rh_sel ) 
				RH 		<= dat_rh*367/10000 - 15955/1000000 - 20468/10000;
			else
				TEMP	<= dat_temp/100 - 397/10;
		end
	end
end

// 7segment of display
seven_seg display (
    clock,
    reset,
    TEMP[3:0],
    TEMP[7:4],
    TEMP[11:8],
    {2'b00,TEMP[13:12]},
    anode,
    led_code
);

endmodule
