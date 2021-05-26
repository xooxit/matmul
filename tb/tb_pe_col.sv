
`timescale 1ns / 1ps
////////////////////////////////////////////////////////////

// Description: Testbench for bfp16 PE columns, DEPTH = 2

// TestCase: Matrix X vector
// input	 : 4x8 ifmap 8x1 weight


// Note: Rough test 
////////////////////////////////////////////////////////////

module tb_pe_col ();

	parameter DATA_TYPE = 16; // data type width
	parameter NUM_TEST = 24;

	reg clk = 0;
	reg rst = 1;

	reg [NUM_TEST*DATA_TYPE-1:0] input_ifmap [0:7] = 
		// 4X8 ifmap matrix
		//////////////////////////////
    // 1(0x3f80)	1	1	1	1	1	1	1 // 	
    // 1(0x3f80)	1	1	1	1	1	1	1 // 	
    // 1(0x3f80)	1	1	1	1	1	1	1 // 	
    // 1(0x3f80)	1	1	1	1	1	1	1 // 	
		//////////////////////////////
    {384'h0000_0000_0000_0000_0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_0000_0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
		 384'h0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000};
    
	reg [NUM_TEST*DATA_TYPE-1:0] input_weight = 
		// 8X1 weight vector
		////////////////////
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
    // 1 		(0x3F80)	//
		////////////////////
		384'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_3f80_3f80_3f80_3f80_3f80_3f80_3f80_3f80;


	reg [NUM_TEST-1:0] input_ctrl = 24'b1111_1111_1111_1111_0000_0000;

	reg [8*DATA_TYPE-1:0] ifmap;
	reg [DATA_TYPE-1:0] 	weight;
	reg	ctrl;
	// reg counter;

	reg [8*DATA_TYPE-1:0] out_ifmap;
	reg [DATA_TYPE-1:0] out;  
	// 4X1 output
	////////////////////
	//	8 (0x4100)		//
	//	8 (0x4100)		//
	//	8 (0x4100)		//
	//	8 (0x4100)		//
	////////////////////	

	// Generate simulation clock
	always #5 clk = !clk;

	reg [5:0] counter;


	always @ ( posedge clk ) begin
		ctrl 	  <= input_ctrl[counter];
		ifmap   <= {input_ifmap[0][16*counter +: 16], input_ifmap[1][16*counter +: 16],
								input_ifmap[2][16*counter +: 16], input_ifmap[3][16*counter +: 16],
								input_ifmap[4][16*counter +: 16], input_ifmap[5][16*counter +: 16],
								input_ifmap[6][16*counter +: 16], input_ifmap[7][16*counter +: 16]};
		weight  <= input_weight[16*counter +: 16];		
	
	// set the input values per clock cycle 
	/*
	always @ (posedge clk) begin
		ctrl 	 = input_ctrl[counter];
		ifmap  = input_ifmap[0:1][16*(counter+1)-1:16*counter];
		weight = input_weight[16*(counter+1)-1:16*counter];
	*/
		if (counter < NUM_TEST-1) begin
			counter = counter + 1'b1;
		end else begin
			counter = 'd0;
		end
	end

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