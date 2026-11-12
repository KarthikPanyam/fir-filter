module fir_controller (
	input clk, rst,
	input x_valid,
	output reg y_valid);
	
reg valid_mid;

	always@ (posedge clk) begin
		if(rst) 
			valid_mid<=0;
			
		else begin
		
			valid_mid <= x_valid;
		end
	
	end
	
	
	
	always@(posedge clk)begin
		if(rst)
			y_valid <=0;
		else
			y_valid <= valid_mid;
			
	end
	
	
endmodule
