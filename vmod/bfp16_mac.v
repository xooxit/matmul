
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////
// BFP16 Multiply-and-Accumlate
// BFP16Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// calculates weight * ifmap + psum = out 
// within 1 clock
//  

// NOTE: Verification delay, Synchronizing
/////////////////////////////////////////////////////////////

module bfp16_mac(clk, rst, W, I, P, O);

	input clk, rst; 
	input [15:0] W, I, P;
	output [15:0] O;

	wire [15:0] mult_out;


	bfp16_mult _multipiler(
	.clk(clk),	
	.rst(rst),
	.A(W),
	.B(I),
	.O(mult_out)
	);

	bfp16_adder _adder(
	.clk(clk),	
	.rst(rst),
	.A(mult_out),
	.B(P),
	.O(O)
	);




endmodule


	


