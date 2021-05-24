`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// FP32 and BP16 Adder 

// https://github.com/danshanley/FPU/blob/master/fpu.v

// Format: 1-bit signed, 8-bit exponents, 23-bit fractions
// Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// NOTE: MORE VERIFICATION NEEDED
/////////////////////////////////////////////////////////////

module bfp16_adder(clk, rst, A, B, O);
	input [15:0] A, B;
	input clk;
	input rst;
	output [15:0] O;

	wire a_sign;
	wire b_sign;
	wire [7:0] a_exponent;
	wire [7:0] b_exponent;
	wire [7:0] a_mantissa;
	wire [7:0] b_mantissa;

	reg o_sign;
	reg [7:0] o_exponent;
	reg [7:0] o_mantissa;

	reg [15:0] adder_a_in;
	reg [15:0] adder_b_in;
	wire[15:0] adder_out;
	
	assign a_sign = A[15];
	assign a_exponent = A[14:7];
	assign a_mantissa = {1'b1, A[6:0]};
	assign b_sign = B[15];
	assign b_exponent = B[14:7];
	assign b_mantissa = {1'b1, B[6:0]};
	
	assign O = {o_sign, o_exponent, o_mantissa[6:0]};

	gAdder _gAdder(
		.a(adder_a_in),
		.b(adder_b_in),
		.out(adder_out)
	);

	reg [1:0] state;

	always @ ( * ) begin
		if (rst == 1'b1) begin
			adder_a_in = 0;	//dummy
			adder_b_in = 0;	//dummy
			o_sign = 0;
			o_exponent = 0;
			o_mantissa = 0;
		//If A is zero and B is inf, return NaN
		end else if ((a_exponent == 0 && a_mantissa[6:0] == 0) && (b_exponent == 255 && b_mantissa[6:0] == 0)) begin
			adder_a_in = 0;	//dummy
			adder_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//If A is inf and B is zero, return NaN
		end else if ((a_exponent == 255 && a_mantissa[6:0] == 0) && (b_exponent == 0 && b_mantissa[6:0] == 0)) begin
			adder_a_in = 0;	//dummy
			adder_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//If A is inf and B is -inf, return NaN
		end else if ((a_exponent == 255 && a_mantissa[6:0] == 0) && (b_exponent == 255 && b_mantissa[6:0] == 0) && (a_sign != b_sign)) begin
			adder_a_in = 0;	//dummy
			adder_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//If A is NaN or B is zero, return A	
		end else if ((a_exponent == 255 && a_mantissa[6:0] != 0) || (b_exponent == 0 && b_mantissa[6:0] == 0)) begin
			state = 2'b00;	//debug
			adder_a_in = 0;	//dummy
			adder_b_in = 0;	//dummy
			o_sign = a_sign;
			o_exponent = a_exponent;
			o_mantissa = a_mantissa;
		//If B is NaN or A is zero, return B	
		end else if ((a_exponent == 0 && a_mantissa[6:0] == 0) || (b_exponent == 255 && b_mantissa[6:0] != 0)) begin 
			state = 2'b01;	//debug
			adder_a_in = 0; //dummy
			adder_b_in = 0;	//dummy
			o_sign = b_sign;
			o_exponent = b_exponent;
			o_mantissa = b_mantissa;
		//If A or B is inf, return inf
		end else if ((a_exponent == 255 && a_mantissa[6:0] == 0) || (b_exponent == 255 && b_mantissa[6:0] == 0)) begin	
			state = 2'b10;	//debug
			adder_a_in = 0; //dummy
			adder_b_in = 0;	//dummy
			o_sign = a_sign ^ b_sign;
			o_exponent = 255;
			o_mantissa = 0; 
		end else begin
			state = 2'b11;	//debug
			adder_a_in = A;
			adder_b_in = B;
			o_sign = adder_out[15];
			o_exponent = adder_out[14:7];
			o_mantissa = adder_out[6:0];
		end
	end
 
endmodule

module gAdder(a, b, out);

	input [15:0] a, b;
	output [15:0] out;

	reg a_sign;
	reg b_sign;
  reg [7:0] a_exponent;
  reg [7:0] b_exponent;
  reg [7:0] a_mantissa;
  reg [7:0] b_mantissa;   
  
  reg o_sign;
  reg [7:0] o_exponent;
  reg [8:0] o_mantissa; 

	reg [1:0] sel;
	// 0 : exp same
	// 1 : exp a > exp b 
	// 2 : exp a < exp b
  reg [7:0] diff;
	reg [7:0] o_exponent_tmp;
  reg [8:0] o_mantissa_tmp;

  reg [7:0] i_e;
  reg [8:0] i_m;
  wire [7:0] o_e;
  wire [8:0] o_m;

          
	addition16_normaliser norm1(
   	.in_e(i_e),
	  .in_m(i_m),
	  .out_e(o_e),
	  .out_m(o_m)
	);

	assign out[15] = o_sign;
	assign out[14:7] = o_exponent;
	assign out[6:0] = o_mantissa[6:0];

	always @ (*) begin
  
		a_sign = a[15];
   	if(a[14:7] == 0) begin
			a_exponent = 8'b00000001;		 
			a_mantissa = {1'b0, a[6:0]};
		end else begin
			a_exponent = a[14:7];
			a_mantissa = {1'b1, a[6:0]};
	 	end
     
		b_sign = b[15];
	 	if(b[14:7] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[6:0]};
		end else begin
			b_exponent = b[14:7];
			b_mantissa = {1'b1, b[6:0]};
		end
     
		// o_exponent		
		if (a_exponent == b_exponent) begin 
			o_exponent_tmp = a_exponent;
			diff = 0;
			sel  = 0; 
		end else if(a_exponent > b_exponent) begin
			o_exponent_tmp = a_exponent;
			diff = a_exponent - b_exponent;
			b_mantissa = b_mantissa >> diff;
			sel = 1;
		end else begin
			o_exponent_tmp = b_exponent;
			diff = b_exponent - a_exponent;
			a_mantissa = a_mantissa >> diff;
			sel = 2;
		end

		// o_mantissa, o_sign
		if (a_sign == b_sign) begin
			o_sign = a_sign;
			o_mantissa_tmp = a_mantissa + b_mantissa;	
		end else if (sel == 1) begin
			o_sign = a_sign;
			o_mantissa_tmp = a_mantissa - b_mantissa;
		end else if (sel == 2) begin
			o_sign = b_sign;
			o_mantissa_tmp = a_mantissa - b_mantissa;
		end else begin
			o_sign = a_sign;
			o_mantissa_tmp = a_mantissa - b_mantissa;
		end
		
		// case handling
		// first case 
		if (o_mantissa_tmp[8] == 1) begin
			if (o_exponent_tmp == 254) begin
				// return inf
				o_exponent = 255;
				o_mantissa = 0;
			end else begin
				// return shift 1
				o_exponent = o_exponent_tmp + 1;
				o_mantissa = o_mantissa_tmp >> 1;
			end
		// second case
		end else if (o_mantissa_tmp[7] != 1) begin
			// normalization
			i_e = o_exponent_tmp;
	    i_m = o_mantissa_tmp;
	    o_exponent = o_e;
	    o_mantissa = o_m;
		// last case
		end else begin
			o_exponent = o_exponent_tmp;
			o_mantissa = o_mantissa_tmp;
		end

	end
 
endmodule

module addition16_normaliser (in_e, in_m, out_e, out_m);

	input [7:0] in_e;
	input [8:0] in_m;
	output [7:0] out_e;
	output [8:0] out_m;
  
	wire [7:0] in_e;
	wire [8:0] in_m;
	reg [7:0] out_e;
	reg [8:0] out_m;

	reg [2:0] state; 	 //debug
	reg [1:0] instate; //debug

	always @ (*) begin
		if (in_m[7:0] == 8'b00000000) begin // 0.000000001 = o_mantissa starts as
			state = 3'b000; //debug
			out_e = 0;
			out_m = 0; 
		end else if (in_m[7:0] == 8'b00000001) begin // 0.00000001 = o_mantissa starts as
			state = 3'b001; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 7) begin
				instate = 1;  //debug
				out_e = in_e - 7;
				out_m = in_m << 7;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
	  end else if (in_m[7:1] == 7'b0000001) begin // 0.000001	 = o_mantissa starts as
			state = 3'b010; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 6) begin
				instate = 1;  //debug
				out_e = in_e - 6;
				out_m = in_m << 6;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
		end else if (in_m[7:2] == 6'b000001) begin // 0.00001 = o_mantissa starts as
			state = 3'b011; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 5) begin
				instate = 1;  //debug
				out_e = in_e - 5;
				out_m = in_m << 5;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
		end else if (in_m[7:3] == 5'b00001) begin // 0.0001 = o_mantissa starts as
			state = 3'b100; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 4) begin
				instate = 1;  //debug
				out_e = in_e - 4;
				out_m = in_m << 4;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
			/* for example
			end else if (in_e == 2) begin
				out_e = 0;
				out_m = in_m << 1;
			end else if (in_e == 3) begin
				out_e = 0;
				out_m = in_m << 2;
			end
		*/
		end else if (in_m[7:4] == 4'b0001) begin // 0.001 = o_mantissa starts as
			state = 3'b101; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 1) begin
				instate = 1;  //debug
				out_e = in_e - 3;
				out_m = in_m << 3;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
		end else if (in_m[7:5] == 3'b001) begin // 0.01 = o_mantissa starts as
			state = 3'b110; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m;
			end else if (in_e > 2) begin
				instate = 1;  //debug
				out_e = in_e - 2;
				out_m = in_m << 2;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end
		end else if (in_m[7:6] == 2'b01) begin // 0.1 = o_mantissa starts as
			state = 3'b111; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m;
			end else begin
				instate = 1;  //debug
				out_e = in_e - 1;
				out_m = in_m << 1;
			end
		end else begin
		// Nothing
		end

	end


endmodule
 
