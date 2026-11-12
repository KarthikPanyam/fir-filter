module fir_top (
	input signed [7:0] xin,
	input x_valid,
	input clk, rst,
	input coeff_ld,
	input signed [31:0] coeff_in,
	
	output wire signed [17:0] yout,
	output wire y_valid);
	
	
	fir_d filter1( .clk(clk), .rst(rst), .xin(xin), .shift_en(x_valid), .coeff_ld(coeff_ld), .coeff_in(coeff_in), .yout(yout) );
	
	fir_controller control1( .clk(clk), .rst(rst), .x_valid(x_valid), .y_valid(y_valid) );
	
	
endmodule