`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Design: tb_mult.v
// Author: Eric Qin

// Description: Testbench for BFP16 Multiplier

////////////////////////////////////////////////////////////

module tb_mult ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TESTS = 9;

	reg clk = 0;
	reg rst = 0;

	reg [DATA_TYPE-1:0] input_A [0:NUM_TESTS-1] = 
    // very small, 8, 1024, 3
    {16'h007e, 16'h0040, 16'h1c60, 16'h007e, 16'h0080, 16'h003F, 16'h003F, 16'h003f, 16'h0000};
    
	reg [DATA_TYPE-1:0] input_B [0:NUM_TESTS-1] = 
    // 1,2,4,8,16,32,64,128
    {16'h007e, 16'h4000, 16'h2060, 16'h3c7e, 16'h3c00, 16'h3F02, 16'h3F82, 16'h4002, 16'h0000};
    
	reg [10:0] counter = 'd0;

	reg [DATA_TYPE-1:0] O; // Expected = // 0x005E , 
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
	bfp16_mult my_mult(
		.clk(clk),
		.rst(rst),
		.A(A),
		.B(B),
		.O(O)
	);

	// Print the mux inputs...
	initial begin
		#1000 $finish;
	end

/*
	initial begin
		$vcdplusfile("mult.vpd");
	 	$vcdpluson(0, tb_mult); 
		#100 $finish;
	end
*/
endmodule

