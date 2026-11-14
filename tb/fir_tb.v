`timescale 1ns/1ps

module fir_tb ();

	reg signed [7:0] xin;
	reg x_valid;
	reg clk, rst;
	reg coeff_ld;
	reg signed [31:0] coeff_in;
	
	wire signed [17:0] yout;
	wire y_valid;
	
	reg signed [17:0] expected_values [0:3]; 

	integer i, error;
	
	fir_top dut( .clk(clk), .rst(rst), .xin(xin), .x_valid(x_valid), .coeff_in(coeff_in), .coeff_ld(coeff_ld), .yout(yout), .y_valid(y_valid));
	
	
	initial clk = 1'b0;
	
	always #5 clk = ~ clk;
	


	initial begin
	i = 0;
	error = 0;
	
		expected_values[0] = 18'sd16;
		expected_values[1] = 18'sd48;
		expected_values[2] = 18'sd48;
		expected_values[3] = 18'sd16;
	end
	
	
	
	always @ (posedge clk) begin
		if(y_valid) begin
			if(yout === expected_values[i]) begin
				$display("Correct value\n");
				i = i+1;
			end
			
			else begin
				$display("Mismatch");
				error = error + 1;
				i = i+1;
			end
			
		end
		
	end
	
	
	initial begin
	//$dumpfile("dump.vcd");
	//$dumpvars(0, fir_tb);
	
	

		reset_dut();
		load_coeff(16, 48, 48, 16);
		send_data(1);
		
		send_data(0);
		send_data(0);
		send_data(0);
		
		junk_valid ();
		repeat (3) @(posedge clk);
		reset_dut();
		
		
		
		
		repeat (3) @(posedge clk);
		
		
		if(( error !=0) || (i!=4) )
			$display("FAIL\n");
		else
			$display("PASS\n");
		
		$finish();
	end
	
	
	
	task reset_dut ();
	begin
		rst <=1'b1;
		xin <= 8'sd0;
		x_valid <=1'b0;
		coeff_in <= 32'sd0;
		coeff_ld <= 1'b0;
		
		@(posedge clk);
		
		rst <= 1'b0;
	end
	endtask
	
	
	
	task load_coeff( input signed [7:0] h0, h1, h2, h3);
	begin
		coeff_in <= {h0, h1, h2, h3};
		coeff_ld <= 1'b1;
		x_valid <= 1'b0;
		@(posedge clk);
		
		coeff_ld <= 1'b0;
	end
	endtask
	
	
	
	task send_data( input signed [7:0] data);
	begin
	
		x_valid <= 1'b1;
		coeff_ld <= 1'b0;
		
		xin <= data;
		
		@(posedge clk);
		x_valid <= 1'b0;
	end	
	endtask
	
	
	task junk_valid ();
	begin
		x_valid <= 1'b0;
		xin <= 8'sd12;
		
		@(posedge clk);
	end
	endtask
	
	
	
endmodule

	