`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////
// BFP16 Multiplier 

// https://github.com/danshanley/FPU/blob/master/fpu.v
// with slight modifications to turn FP32 to BFP16
// for area approximation

// Format: 1-bit signed, 8-bit exponents, 7-bit fractions

// NOTE: MORE VERIFICATION NEEDED
/////////////////////////////////////////////////////////////

module bfp16_mult(clk, rst, A, B, O);

  input [15:0] A, B;
	input rst, clk;
  output [15:0] O;

  wire a_sign;
  wire b_sign;
  wire [7:0] a_exponent;
  wire [7:0] b_exponent;
  wire [7:0] a_mantissa;
  wire [7:0] b_mantissa;
  wire [15:0] O;
             
  reg o_sign;
  reg [7:0] o_exponent;
  reg [8:0] o_mantissa;  
	
  reg [15:0] multiplier_a_in;
  reg [15:0] multiplier_b_in;
  wire [15:0] multiplier_out;

  assign O[15] = o_sign;
  assign O[14:7] = o_exponent;
  assign O[6:0] = o_mantissa[6:0];

  assign a_sign = A[15];
  assign a_exponent[7:0] = A[14:7];
  assign a_mantissa[7:0] = {1'b1, A[6:0]};

  assign b_sign = B[15];
  assign b_exponent[7:0] = B[14:7];
  assign b_mantissa[7:0] = {1'b1, B[6:0]};

  gMultiplier _gMultiplier (
		.a(multiplier_a_in),
		.b(multiplier_b_in),
		.out(multiplier_out)
	);
	
  //assign multiplier_a_in = A; // timing fix - singly cycle
  //assign multiplier_b_in = B; // timing fix - single cycle
	reg [2:0] state;

  always @ ( * ) begin //Multiplication
		if (rst == 1'b1) begin
			state = 3'b000;				//debug
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
			o_sign = 0;
	  	o_exponent = 0;
	  	o_mantissa = 0;
    //If a is NaN return NaN
    end else if (a_exponent == 255 && a_mantissa[6:0] != 0) begin
			state = 3'b001;				//debug
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//If b is NaN return NaN
		end else if (b_exponent == 255 && b_mantissa[6:0] != 0) begin
			state = 3'b010;				//debug
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//if a is zero and b is inf return NaN
		end else if((a_exponent == 0 && a_mantissa[6:0] == 0) && b_exponent == 255) begin
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//if b is zero and a is inf return NaN
		end else if((b_exponent == 0 && b_mantissa[6:0] == 0) && a_exponent == 255) begin
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
			o_sign = 1'b1;
			o_exponent = 7'b1111111;
			o_mantissa = 8'b11111111;
		//If a or b is 0 return 0
		end else if ((a_exponent == 0 && a_mantissa[6:0] == 0) || (b_exponent == 0 && b_mantissa[6:0] == 0)) begin
			state = 3'b011;				//debug
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
	  	o_sign = 0;
		  o_exponent = 0;
	 		o_mantissa = 0;
		//if a or b is inf return inf
		end else if (a_exponent == 255 || b_exponent == 255) begin
			state = 3'b100;				//debug
			multiplier_a_in = 0;	//dummy
			multiplier_b_in = 0;	//dummy
	  	o_sign = a_sign;
	  	o_exponent = 255;
	  	o_mantissa = 0;
		end else begin // Passed all corner cases
			state = 3'b101;				//debug
	  	multiplier_a_in = A;
	  	multiplier_b_in = B;
	  	o_sign = multiplier_out[15];
	  	o_exponent = multiplier_out[14:7];
	  	o_mantissa = multiplier_out[6:0]; 
    end
  end

endmodule


module gMultiplier(a, b, out);
  input  [15:0] a, b;
  output [15:0] out;
  wire [15:0] out;
  reg a_sign;
  reg [7:0] a_exponent;
  reg [7:0] a_mantissa;
  reg b_sign;
  reg [7:0] b_exponent;
  reg [7:0] b_mantissa;

  reg o_sign;
  reg [8:0] o_exponent; // fix? [8:0] o_exponent
  reg [8:0] o_exponent_tmp;
  reg [8:0] o_exponent_sum;
  reg [7:0] o_exponent_minus;
	reg [7:0] o_exponent_shift;
  reg [8:0] o_mantissa;

  reg [15:0] product;

  assign out[15] = o_sign;
  assign out[14:7] = o_exponent;
  assign out[6:0] = o_mantissa[6:0];

  reg  [7:0] i_e;
  reg  [15:0] i_m;
  wire [7:0] o_e;
  wire [15:0] o_m;

	reg state1;
	reg state2;
	reg[1:0] state3;

	wire [15:0] tmp;

  assign tmp[15] = o_sign;
  assign tmp[14:7] = o_exponent[7:0];
  assign tmp[6:0] = o_mantissa[6:0];

  multiplication_normaliser norm1
  (
		.in_e(i_e),
		.in_m(i_m),
		.out_e(o_e),
		.out_m(o_m)
	);

  always @ ( * ) begin
		
		a_sign = a[15];
		if(a[14:7] == 0) begin
			//Denorm number
			state1 = 0;
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[6:0]};
		end else begin
			state1 = 1;
			a_exponent = a[14:7];
			a_mantissa = {1'b1, a[6:0]};
		end
   
		b_sign = b[15];
		if(b[14:7] == 0) begin
			//Denorm number
			state2 = 0;
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[6:0]};
		end else begin
			state2 = 1;
			b_exponent = b[14:7];
			b_mantissa = {1'b1, b[6:0]};
		end
   
    o_sign 							= a_sign ^ b_sign;
		o_exponent_sum			= a_exponent + b_exponent; // 2(1+1) ~ 508(254+254)
		o_exponent_tmp			= o_exponent_sum < 127 ? 0 : o_exponent_sum - 127; //debug
	  o_exponent 					= o_exponent_sum < 127 ? 0 : o_exponent_sum - 127; // 0 ~ 381
		o_exponent_minus		= o_exponent_sum < 127 ? 127 - o_exponent_sum : 0; // 0 ~ 125
		o_exponent_shift		= o_exponent_minus + 1; // 1 ~ 126
    product 						= a_mantissa * b_mantissa;

		// infinity
		if (o_exponent >= 255) begin
			o_exponent 	= 255;
			product 		= 0;
		// Normalization
		end else if (o_exponent != 0) begin // 0 < o_exponent < 255
			if (product[15] == 1 && (o_exponent + 1) == 255) begin
				// infinity
				o_exponent 	= 255;
				product 		= 0;
			end else if (product[15] == 1) begin
				// normal 
				o_exponent 	= o_exponent + 1;
				product 		= product >> 1;
			end else if (product[14] != 1) begin
				// denormal
	      i_e 				= o_exponent;
	      i_m 				= product;
	      o_exponent 	= o_e;
	      product 		= o_m;
			end else begin
				//noraml 
				o_exponent 	= o_exponent;
				product 		= product;
			end
		end else begin // 0 == o_exponent
			// makes denormed format
			product = product >> o_exponent_shift;
			o_exponent = 1;
			if (product[15] == 1) begin
				// nothing because 'o_exponent_shift' is equal or bigger than 1
			end else if (product[14] != 1) begin
				// denormed out
				o_exponent = 0;
				product = product;
			end else begin
				// normal out
				o_exponent = o_exponent;
				product = product;
			end
		end

		o_mantissa = product[14:7];

  end


endmodule


// Denormalized Number Handling
module multiplication_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [15:0] in_m;
  output [7:0] out_e;
  output [15:0] out_m;

  wire [7:0] in_e;
  wire [15:0] in_m;
  reg [7:0] out_e;
  reg [15:0] out_m;
	
	reg [2:0] state;  //debug
	reg [1:0] instate;//debug

  always @ ( * ) begin
		if (in_m[14:0] == 15'b000000000000001) begin // 0.00000000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 14) begin
				instate = 1;  //debug
				out_e = in_e - 14;
				out_m = in_m << 14;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end if (in_m[14:1] == 14'b00000000000001) begin // 0.0000000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 13) begin
				instate = 1;  //debug
				out_e = in_e - 13;
				out_m = in_m << 13;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:2] == 13'b0000000000001) begin // 0.000000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 12) begin
				instate = 1;  //debug
				out_e = in_e - 12;
				out_m = in_m << 12;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:3] == 12'b000000000001) begin // 0.00000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 11) begin
				instate = 1;  //debug
				out_e = in_e - 11;
				out_m = in_m << 11;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:4] == 11'b00000000001) begin // 0.0000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 10) begin
				instate = 1;  //debug
				out_e = in_e - 10;
				out_m = in_m << 10;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:5] == 10'b0000000001) begin // 0.000000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 9) begin
				instate = 1;  //debug
				out_e = in_e - 9;
				out_m = in_m << 9;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:6] == 9'b000000001) begin // 0.00000001 = o_mantissa starts as
			state = 3'b000; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 8) begin
				instate = 1;  //debug
				out_e = in_e - 8;
				out_m = in_m << 8;
			end else begin
				instate = 2;  //debug
				out_e = 0;
				out_m = in_m << (in_e-1);
			end	
		end else if (in_m[14:7] == 8'b00000001) begin // 0.0000001 = o_mantissa starts as
			state = 3'b000; //debug
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
		end else if (in_m[14:8] == 7'b000001) begin // 0.000001 = o_mantissa starts as
			state = 3'b001; //debug
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
	  end else if (in_m[14:9] == 6'b000001) begin // 0.00001 = o_mantissa starts as
			state = 3'b010; //debug
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
		end else if (in_m[14:10] == 5'b00001) begin // 0.0001 = o_mantissa starts as
			state = 3'b011; //debug
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
		end else if (in_m[14:11] == 4'b0001) begin // 0.001
			state = 3'b100; //debug
			if (in_e < 2) begin
				instate = 0;  //debug
				out_e = 0;
				out_m = in_m; 
			end else if (in_e > 3) begin
				instate = 1;  //debug
				out_e = in_e - 3;
				out_m = in_m << 3;
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
		end else if (in_m[14:12] == 3'b001) begin // 0.01
			state = 3'b101; //debug
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
				out_m = in_m << 1;
			end
		end else if (in_m[14:13] == 2'b01) begin
			state = 3'b110; //debug
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
			//nothing
			//state = 3'b111; //debug // product[14] == 1 
			//out_e = in_e;
			//out_m = in_m;
		end
  end
endmodule
