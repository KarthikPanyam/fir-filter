module fir_d ( 
			input clk, rst,
			input signed [7:0] xin,
			input shift_en,
			input coeff_ld,
			input signed [31:0] coeff_in,
			
			
			output reg signed [17:0] yout
);
			
			
			
	reg signed [7:0] sipo [0:2];
	reg signed [7:0] coeff[0:3];
	reg signed [15:0] product [0:3];
	wire signed [15:0] product_w[0:3];
	wire signed [16:0]adder1, adder2;
	wire signed [17:0] adder3;
	
	integer i,j,k;
	
	//---- SIPO START ----
	
	always @ (posedge clk) begin
		if(rst) begin
			for(i =0; i<=2; i = i+1) 
				sipo[i] <= 0;			
		end
		
		else begin
			
			if (shift_en) begin
			
				sipo[0] <= xin;
				sipo[1] <= sipo[0];
				sipo[2] <= sipo[1];
			
			end			
		end		
	end
	
	//---- SIPO END ----	
	
	//---- COEFF START ----
	
	always @(posedge clk) begin
		if(rst) begin
			for(j =0; j<=3; j = j+1) 
				coeff[j] <= 0;			
		end
		
		else begin			
			if (coeff_ld) begin
				coeff[0] <= coeff_in[31:24];
				coeff[1] <= coeff_in[23:16];
				coeff[2] <= coeff_in[15:8];
				coeff[3] <= coeff_in[7:0];
			end
			
		end
	end
	
	
	//---- COEFF END----	
	
	
	
	assign	product_w[0] = xin 	   * coeff[0];
	assign	product_w[1] = sipo[0] * coeff[1];
	assign	product_w[2] = sipo[1] * coeff[2];
	assign	product_w[3] = sipo[2] * coeff[3];
	
	
	
	//---- PRODUCT START----		
	
	always @ (posedge clk) begin
		if(rst) begin
			for(k =0; k<=3; k = k+1) 
				product[k] <= 0;			
		end
		
		else begin
			if(shift_en) begin
				product[0] <= product_w[0];
				product[1] <= product_w[1];
				product[2] <= product_w[2];
				product[3] <= product_w[3];
			end
		end
		
			
	end
	
	//---- PRODUCT END----		
	
	
	
		assign adder1 = product[0] + product[1];
		assign adder2 = product[2] + product[3];		
		assign adder3 = adder1 + adder2;
		
	
	
	
	always @(posedge clk) begin
		if(rst)
			yout <= 0;
			
		else 			
			yout <= adder3;
		
		
	end
	
	
endmodule
