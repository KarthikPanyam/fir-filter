`timescale 1ns/1ps

module fir_tb ();

	reg signed [7:0] xin;
	reg x_valid;
	reg clk, rst;
	reg coeff_ld;
	reg signed [31:0] coeff_in;
	
	wire signed [17:0] yout;
	wire y_valid;
	
	
	
	fir_top dut( .clk(clk), .rst(rst), .xin(xin), .x_valid(x_valid), .coeff_in(coeff_in), .coeff_ld(coeff_ld), .yout(yout), .y_valid(y_valid));
	
	
	initial clk = 1'b0;
	
	always #5 clk = ~ clk;
	
	initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, fir_tb);

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
		
		$finish();
	end
	
	
	
	task reset_dut ();
		rst <=1'b1;
		xin <= 8'sd0;
		x_valid <=1'b0;
		coeff_in <= 32'sd0;
		coeff_ld <= 1'b0;
		
		@(posedge clk);
		
		rst <= 1'b0;
	endtask
	
	
	
	task load_coeff( input signed [7:0] h0, h1, h2, h3);
		coeff_in <= {h0, h1, h2, h3};
		coeff_ld <= 1'b1;
		x_valid <= 1'b0;
		@(posedge clk);
		
		coeff_ld <= 1'b0;
	endtask
	
	
	
	task send_data( input signed [7:0] data);
		x_valid <= 1'b1;
		coeff_ld <= 1'b0;
		
		xin <= data;
		
		@(posedge clk);
		x_valid <= 1'b0;
		
	endtask
	
	
	task junk_valid ();
		x_valid <= 1'b0;
		xin <= 8'sd12;
		
		@(posedge clk);
	endtask
	
	
	
endmodule

	