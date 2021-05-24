`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Design: tb_add.v
// Author: Eric Qin

// Description: Testbench for BFP16 Adder

////////////////////////////////////////////////////////////

module tb_add ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TESTS = 6;

	reg clk = 0;
	reg rst = 1;

	reg [DATA_TYPE-1:0] input_A [0:NUM_TESTS-1] = 
    // 
    {16'h04f8, 16'h04f8, 16'h0030, 16'h00c0, 16'h0188, 16'h0188};
    
	reg [DATA_TYPE-1:0] input_B [0:NUM_TESTS-1] = 
    // 0, 1240, 8192, 2.5
    {16'h00c0, 16'h80c0, 16'h8020, 16'h8040, 16'h0040, 16'h8040};
    
	reg [10:0] counter = 'd0;

	reg [DATA_TYPE-1:0] O; // Expected = 0x01e0, 0x0050, 0x0010, 0x0080, 0x0198, 0x0170 
	reg [DATA_TYPE-1:0] A;
	reg [DATA_TYPE-1:0] B;

	// Generate simulation clock
	always #1 clk = !clk;

	// set the input values per clock cycle
	always @ (posedge clk) begin
		A = input_A[counter];
		B = input_B[counter];
		if (counter < NUM_TESTS-1) begin
			counter = counter + 1'b1;
		end else begin
			counter = 'd0;
		end
	end

	// instantiate system
	bfp16_adder my_adder(
		.clk(clk),
		.rst(rst),
		.A(A),
		.B(B),
		.O(O)
	);

	// Print the mux inputs...
	initial begin
		#1 rst = 0;

		#1000 $finish;
	end

	/*
	initial begin
		$vcdplusfile("adder.vpd");
	 	$vcdpluson(0, tb_add); 
		#100 $finish;
	end
	*/
endmodule

