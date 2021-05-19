
`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Description: Testbench for bfp16 PE columns, DEPTH = 2

// TestCase: Matrix X vector
// input	 : 4x2 ifmap 2x1 weight


// Note: Rough test 
////////////////////////////////////////////////////////////

module tb_pe_col ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TEST = 8;

	reg clk = 0;
	reg rst = 1;

	reg [NUM_TEST*DATA_TYPE-1:0] input_ifmap [0:1] = 
		// 4X2 ifmap matrix
		////////////////////////////
    // 3(0x4040)		8(0x4100)	//
		// 3						8					//
		// 3						8					//
		// 3						8					//
		////////////////////////////
    {128'h0000_0000_4040_4040_4040_4040_0000_0000, 128'h0000_0000_0000_4100_4100_4100_4100_0000};
    
	reg [NUM_TEST*DATA_TYPE-1:0] input_weight = 
		// 2X1 weight vector
		////////////////////
    // 1 		(0x3F80)	//
		// 1240 (0x449B)	//
		////////////////////
		128'h449B_3F80_0000_0000_0000_0000_0000_0000;	

	reg [NUM_TEST-1:0] input_ctrl = 8'b0011_1110;

	reg [2*DATA_TYPE-1:0] ifmap;
	reg [DATA_TYPE-1:0] 	weight;
	reg	ctrl;
	// reg counter;

	reg [2*DATA_TYPE-1:0] out_ifmap;
	reg [DATA_TYPE-1:0] out;  
	// 4X1 output
	////////////////////
	//	9935 (0x461B)	//
	//	9935 (0x461B)	//	
	//  9935 (0x461B)	//
	//  9935 (0x461B)	//
	////////////////////	

	// Generate simulation clock
	always #5 clk = !clk;

	reg [2:0] counter = 3'b111;	

	always @ ( posedge clk ) begin
		counter <= counter - 1'b1;
		ctrl 	  <= input_ctrl[counter];
		ifmap   <= {input_ifmap[0][16*(counter+1)-1 -: 16], input_ifmap[1][16*(counter+1)-1 -: 16]};
		weight  <= input_weight[16*(counter+1)-1 -: 16];		
	end
	// set the input values per clock cycle 
	/*
	always @ (posedge clk) begin
		ctrl 	 = input_ctrl[counter];
		ifmap  = input_ifmap[0:1][16*(counter+1)-1:16*counter];
		weight = input_weight[16*(counter+1)-1:16*counter];

		if (counter < NUM_TEST-1) begin
			counter = counter + 1'b1;
		end else begin
			counter = 'd0;
		end
	end */

	// instantiate system
	bfp16_pe_col my_col(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.weight(weight),
		.ifmap(ifmap),
		.out(out),
		.out_ifmap(out_ifmap)
	);

	// Print the mux inputs...
	initial begin
		#1 rst = 0;

		#1000 $finish;
	end

endmodule