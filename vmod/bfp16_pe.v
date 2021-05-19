`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////
// BFP16 Weight Stationary PE
// BFP16Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// 2-State PE : HOLD or not
// HOLD   - Ready to multiply-and-Add, Pipelined psum
// input 	: ifmap, psum
// output : ifmap, psum
//
// or not - Pipelined weight
// input 	: weight
// output : weight

// NOTE: OPTIMIZATION "Weight Prefetch" TO BE CONSIDERED
/////////////////////////////////////////////////////////////

module bfp16_pe_wsNonOpt(
													clk,
 													rst, 
 													ctrl,
 													in,
 													in_ifmap,
 													out,
 													out_ifmap
 												);

	input clk;
	input rst;
	input ctrl; // ctrl = HOLD
	input  [15:0] in;
	input  [15:0] in_ifmap;
	output [15:0] out;
	output [15:0] out_ifmap;

	reg [15:0] hold_weight;
	reg [15:0] hold_ifmap;
	reg [15:0] hold_psum;

	wire [15:0] input_weight;
	wire [15:0] mac_input_psum;
	wire [15:0] mac_input_weight;
	wire [15:0] mac_output_psum;

	// input demux; choose data path 
	bfp16_demux demux(
		.in(in),
		.out0(input_weight), 			// ctrl = 0 weight pass
		.out1(mac_input_psum),		// ctrl = 1 weight hold psum pass
		.sel(ctrl)
	);

	bfp16_mac mac(
	.clk(clk),
	.rst(rst),
	.W(mac_input_weight),
	.I(in_ifmap),
	.P(mac_input_psum),
	.O(mac_output_psum)
	);

	assign out_ifmap = hold_ifmap;	// directly bypass ifmap 
	assign mac_input_weight = ctrl ? hold_weight : input_weight; // directly inject weight into mac simultaneous store input in reg
	assign out = ctrl ? hold_psum : hold_weight;	// bypass psum only if ctrl == 1, otherwise pipe weight

	// ifmap control
	// always pipelined
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			hold_ifmap <= 0;
		end else begin
			hold_ifmap <= in_ifmap;
		end
	end

	// weight control
	// HOLD 0: pipelined weight
	//			1: hold weight
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			hold_weight <= 0;
		end else begin
			hold_weight <= mac_input_weight;
		end
	end


	// psum control
	// HOLD 0: deactivated
	//			1: pipelined psum
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			hold_psum <= 0;
		end else begin
			hold_psum <= ctrl ? mac_output_psum : 0;
		end
	end

endmodule



module bfp16_demux(in,out0,out1,sel);
	
	input sel;
	input[15:0] in;
	output[15:0] out0,out1;
	
	wire nsel;

	not(nsel,sel);
	and(out0[0],in[0],nsel);
	and(out0[1],in[1],nsel);
	and(out0[2],in[2],nsel);
	and(out0[3],in[3],nsel);
	and(out0[4],in[4],nsel);
	and(out0[5],in[5],nsel);
	and(out0[6],in[6],nsel);
	and(out0[7],in[7],nsel);
	and(out0[8],in[8],nsel);
	and(out0[9],in[9],nsel);
	and(out0[10],in[10],nsel);
	and(out0[11],in[11],nsel);
	and(out0[12],in[12],nsel);
	and(out0[13],in[13],nsel);
	and(out0[14],in[14],nsel);
	and(out0[15],in[15],nsel);

	and(out1[0],in[0],sel);
	and(out1[1],in[1],sel);
	and(out1[2],in[2],sel);
	and(out1[3],in[3],sel);
	and(out1[4],in[4],sel);
	and(out1[5],in[5],sel);
	and(out1[6],in[6],sel);
	and(out1[7],in[7],sel);
	and(out1[8],in[8],sel);
	and(out1[9],in[9],sel);
	and(out1[10],in[10],sel);
	and(out1[11],in[11],sel);
	and(out1[12],in[12],sel);
	and(out1[13],in[13],sel);
	and(out1[14],in[14],sel);
	and(out1[15],in[15],sel);

endmodule

