// 1s = 1000ms = e6us = e9ns
// 1cycle = 10ns
// counter 1s = e8.

module one_second (
	input wire clock,
	input wire reset,
	output wire one_second);
	
	reg [26:0] counter;
	
	always @ (posedge clock or posedge reset ) begin
		if (reset == 1'b1) begin
			counter <= 27'd0;
		end
		else begin
			if (counter ==  27'd100000000) 	counter <= 27'd0;
			else 							counter <= counter + 27'd1;
		end
	end
	
	assign one_second = (counter == 27'd100000000) ? 1'b1 : 1'b0 ; 
	
endmodule	