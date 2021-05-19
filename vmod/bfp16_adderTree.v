`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// bfp16 Adder Tree

// Format: 1-bit signed, 8-bit exponents, 7-bit fractions



// NOTE: 
/////////////////////////////////////////////////////////////



module tree2_to_1(clk, rst, A1, A2, B1, B2, O);
	input [15:0] A1,A2,B1,B2;
	input clk;
	input rst;
	output reg [15:0] O;

	wire [15:0] multiplier1_out;
	wire [15:0] multiplier2_out;
	wire [15:0] adder_out;

	reg [15:0] multiplier1_in_a;
	reg [15:0] multiplier1_in_b;
	reg [15:0] multiplier2_in_a;
	reg [15:0] multiplier2_in_b;




	multiplier gmult1(
		.clk(clk),
		.A(multiplier1_in_a),
		.B(multiplier1_in_b),
		.O(multiplier1_out)
	);

	multiplier gmult2(
		.clk(clk),
		.A(multiplier2_in_a),
		.B(multiplier2_in_b),
		.O(multiplier2_out)
	);
	
	adder16 gadder(
		.clk(clk),
		.rst(rst),
		.A(multiplier1_out),
		.B(multiplier2_out),
		.O(adder_out)
	);


	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			O = 16'd0;
		end else begin
			multiplier1_in_a = A1;
			multiplier1_in_b = B1;
			multiplier2_in_a = A2;
			multiplier2_in_b = B2;
			O = adder_out;
		end
	end

endmodule