`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Description: Testbench for BFP16 DEMUX

////////////////////////////////////////////////////////////

module tb_demux ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TESTS = 4;

	reg clk = 0;
	reg sel = 1;

	reg [DATA_TYPE-1:0] input_A [0:NUM_TESTS-1] = 
    // 3, 8, 1024, 1.25
    {16'h4040, 16'h4100, 16'h4480, 16'h3FA0};
   
	reg [10:0] counter = 'd0;

	reg [DATA_TYPE-1:0] out0,out1; // Expected = 6, 19840, 16777216, 6.25  // 0x40C0, 0x469B, 0x4B80, 0x40C8 
	reg [DATA_TYPE-1:0] in;

	
	// Generate simulation clock
	always #2 clk = !clk;

	// set the input values per clock cycle
	always @ (posedge clk) begin
		in = input_A[counter];
		if (counter < NUM_TESTS-1) begin
			counter = counter + 1'b1;
		end else begin
			counter = 'd0;
		end
	end

	// instantiate system
	bfp16_demux my_demux(
		.sel(sel),
		.in(in),
		.out0(out0),
		.out1(out1)
	);

	// Print the mux inputs...
	initial begin
		#10 sel = 0;
		#10 sel = 1;
		#10 sel = 0;

		#1000 $finish;
	end

endmodule
