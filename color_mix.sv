//
//
// Copyright (c) 2018 Sorgelig
//
// This program is GPL v2+ Licensed.
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

module color_mix
(
	input            clk_vid,
	input            ce_pix,
	input      [2:0] mono,

	input      [7:0] R_in,
	input      [7:0] G_in,
	input      [7:0] B_in,
	input            HSync_in,
	input            VSync_in,
	input            HBlank_in,
	input            VBlank_in,

	output reg [7:0] R_out,
	output reg [7:0] G_out,
	output reg [7:0] B_out,
	output reg       HSync_out,
	output reg       VSync_out,
	output reg       HBlank_out,
	output reg       VBlank_out
);

wire [15:0] px = R_in * 16'd054 + G_in * 16'd183 + B_in * 16'd018;

always @(posedge clk_vid) begin
	if(ce_pix) begin
		if(!mono) begin
			R_out <= R_in;
			G_out <= G_in;
			B_out <= B_in;
		end else begin
			{R_out, G_out, B_out} <= 0;
			case(mono)
				      1: G_out <= px[15:8]; //green
				      2: {R_out, G_out} <= {px[15:8], px[15:8] - px[15:10]}; // amber
				      3: {G_out, B_out} <= {px[15:8], px[15:8]}; // cyan
				default: {R_out, G_out, B_out} <= {px[15:8],px[15:8],px[15:8]}; // gray
			endcase
		end

		HSync_out  <= HSync_in;
		VSync_out  <= VSync_in;
		HBlank_out <= HBlank_in;
		VBlank_out <= VBlank_in;
	end
end

endmodule
