`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////
// BFP16 Weight Stationary PE Columns
// BFP16Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// 2-State PE : HOLD or not
// HOLD   - Ready to multiply-and-Add, Pipelined psum
// input 	: ifmap, psum
// output : ifmap, psum
//
// or not - Pipelined weight
// input 	: weight
// output : weight

//
//
//
//
//
//



// NOTE: OPTIMIZATION "Weight Prefetch" TO BE CONSIDERED
/////////////////////////////////////////////////////////////


module bfp16_pe_col # (
												parameter DEPTH = 2 ) (
												clk,
												rst,
												ctrl,
												weight,
												ifmap,
												out,
												out_ifmap
											);

	input  clk;
	input  rst;
	input  ctrl;
	input  [15:0]	weight;
	input  [31:0] ifmap;
	output [31:0] out_ifmap;
	output [15:0] out;

	wire	 [15:0] bridge;

	bfp16_pe_wsNonOpt pe0(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(weight),
		.in_ifmap(ifmap[16*DEPTH-1:16]),
		.out(bridge),
		.out_ifmap(out_ifmap[16*DEPTH-1:16])
	);

	bfp16_pe_wsNonOpt pe1(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge),
		.in_ifmap(ifmap[16*(DEPTH-1)-1:0]),
		.out(out),
		.out_ifmap(out_ifmap[16*(DEPTH-1)-1:0])
	);

endmodule