`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Description: Testbench for BFP16 Multiply-and-Adder

////////////////////////////////////////////////////////////

module tb_mac ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TESTS = 4;

	reg clk = 0;
	reg rst = 1;

	reg [DATA_TYPE-1:0] input_A [0:NUM_TESTS-1] = 
    // 3, 8, 1024, 1.25
    {16'h4040, 16'h4100, 16'h4480, 16'h3FA0};
    
	reg [DATA_TYPE-1:0] input_B [0:NUM_TESTS-1] = 
    // 1, 1240, 8192, 2.5
    {16'h3F80, 16'h449B, 16'h4600, 16'h4020};

	reg [DATA_TYPE-1:0] input_P [0:NUM_TESTS-1] = 
    // 3, 9920, 8388608, 3.125
    {16'h4040, 16'h4040, 16'h4B00, 16'h4048};	
    
	reg [10:0] counter = 'd0;

	reg [DATA_TYPE-1:0] O; // Expected = 6, 19840, 16777216, 6.25  // 0x40C0, 0x469B, 0x4B80, 0x40C8 
	reg [DATA_TYPE-1:0] A;
	reg [DATA_TYPE-1:0] B;
	reg [DATA_TYPE-1:0] P;
	
	// Generate simulation clock
	always #2 clk = !clk;

	// set the input values per clock cycle
	always @ (posedge clk) begin
		A = input_A[counter];
		B = input_B[counter];
		P = input_P[counter]; 
		if (counter < NUM_TESTS-1) begin
			counter = counter + 1'b1;
		end else begin
			counter = 'd0;
		end
	end

	// instantiate system
	bfp16_mac my_mac(
		.clk(clk),
		.rst(rst),
		.W(A),
		.I(B),
		.P(P),
		.O(O)
	);

	// Print the mux inputs...
	initial begin
		#10 rst = 0;

		#1000 $finish;
	end

endmodule