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
												parameter DEPTH = 8 ) (
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
	input  [16*DEPTH-1:0] ifmap;
	output [16*DEPTH-1:0] out_ifmap;
	output [15:0] out;

	wire	 [15:0] bridge7;
	wire	 [15:0] bridge6;
	wire	 [15:0] bridge5;
	wire	 [15:0] bridge4;
	wire	 [15:0] bridge3;
	wire	 [15:0] bridge2;
	wire	 [15:0] bridge1;



	bfp16_pe_wsNonOpt pe7(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(weight),
		.in_ifmap(ifmap[16*(DEPTH-1)+:16]),
		.out(bridge7),
		.out_ifmap(out_ifmap[16*(DEPTH-1)+:16])
	);

	bfp16_pe_wsNonOpt pe6(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge7),
		.in_ifmap(ifmap[16*(DEPTH-2)+:16]),
		.out(bridge6),
		.out_ifmap(out_ifmap[16*(DEPTH-2)+:16])
	);

	bfp16_pe_wsNonOpt pe5(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge6),
		.in_ifmap(ifmap[16*(DEPTH-3)+:16]),
		.out(bridge5),
		.out_ifmap(out_ifmap[16*(DEPTH-3)+:16])
	);

	bfp16_pe_wsNonOpt pe4(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge5),
		.in_ifmap(ifmap[16*(DEPTH-4)+:16]),
		.out(bridge4),
		.out_ifmap(out_ifmap[16*(DEPTH-4)+:16])
	);

	bfp16_pe_wsNonOpt pe3(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge4),
		.in_ifmap(ifmap[16*(DEPTH-5)+:16]),
		.out(bridge3),
		.out_ifmap(out_ifmap[16*(DEPTH-5)+:16])
	);

	bfp16_pe_wsNonOpt pe2(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge3),
		.in_ifmap(ifmap[16*(DEPTH-6)+:16]),
		.out(bridge2),
		.out_ifmap(out_ifmap[16*(DEPTH-6)+:16])
	);

	bfp16_pe_wsNonOpt pe1(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge2),
		.in_ifmap(ifmap[16*(DEPTH-7)+:16]),
		.out(bridge1),
		.out_ifmap(out_ifmap[16*(DEPTH-7)+:16])
	);

	bfp16_pe_wsNonOpt pe0(
		.clk(clk),
		.rst(rst),
		.ctrl(ctrl),
		.in(bridge1),
		.in_ifmap(ifmap[16*(DEPTH-8)+:16]),
		.out(out),
		.out_ifmap(out_ifmap[16*(DEPTH-8)+:16])
	);

endmodule