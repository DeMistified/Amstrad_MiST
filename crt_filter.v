//------------------------------------------------------------------------------
//
// Extracted to separate entity, converted to verilog, optimized and tweaked
// (c) 2018 Sorgelig
//
//------------------------------------------------------------------------------
//
//    {@{@{@{@{@{@
//  {@{@{@{@{@{@{@{@  This code is covered by CoreAmstrad synthesis r005
//  {@    {@{@    {@  A core of Amstrad CPC 6128 running on MiST-board platform
//  {@{@{@{@{@{@{@{@
//  {@  {@{@{@{@  {@  CoreAmstrad is implementation of FPGAmstrad on MiST-board
//  {@{@        {@{@   Contact : renaudhelias@gmail.com
//  {@{@{@{@{@{@{@{@   @see http://code.google.com/p/mist-board/
//    {@{@{@{@{@{@     @see FPGAmstrad at CPCWiki
//
//------------------------------------------------------------------------------

// https://sourceforge.net/p/jemu/code/HEAD/tree/JEMU/src/jemu/system/cpc/GateArray.java

// altera message_off 10027
module crt_filter
(
	input            CLK,
	input            CE_4,
	input            HSYNC_I,
	input            VSYNC_I,
	output reg       HSYNC_O,
	output reg       VSYNC_O,
	output           SHIFT
);
wire resync = 1;
reg hs4,shift;
assign SHIFT = shift ^ hs4;

// Generate HSync,VSync for monitor
// HSync: delayed by 2us for set, immediate reset and limited by 4us.
// VSync: delayed by 2 lines for set, immediate reset and limited by 2 lines.
always @(posedge CLK) begin
	reg       old_hsync;
	reg       old_vsync,old_vs;
	reg [8:0] hSyncCount;
	reg [9:0] hSyncCount2x;
	reg [8:0] hSyncSize;
	reg       hSyncReg;
	reg [3:0] vSyncCount;
	reg [1:0] syncs;
	reg [8:0] vSyncFlt;

	localparam HFLT_SZ = 50*4;
	localparam VFLT_SZ = 260;

	if(CE_4) begin
		old_hsync <= HSYNC_I;

		if(resync) begin
			if(~&hSyncCount) hSyncCount = hSyncCount + 1'd1;
			if(~old_hsync & HSYNC_I) old_vs <= VSYNC_I;

			//re-align restored hsync to the first hsync of vsync
			if((~old_vs & VSYNC_I & ~old_hsync & HSYNC_I) || (hSyncCount >= hSyncSize)) begin
				hSyncCount = 0;
				if(~old_hsync & HSYNC_I) hSyncReg <= 1;
			end
			
			// Calc line size from length of 2 first lines after VSync
			// 2 lines are needed to neutralize fake interlace video
			if(~&hSyncCount2x) hSyncCount2x = hSyncCount2x + 1'd1;
			if(~old_hsync & HSYNC_I) begin
				if(~VSYNC_I & ~&syncs) syncs = syncs + 1'd1;
				if(VSYNC_I) {syncs,hSyncCount2x} = 0;
				if(syncs == 2) hSyncSize <= hSyncCount2x[9:1];
			end
		end
		else begin
			if(hSyncCount < HFLT_SZ) hSyncCount = hSyncCount + 1'd1;
			else if(~old_hsync & HSYNC_I) begin
				hSyncCount = 0;
				hSyncReg <= 1;
			end
		end

		if(old_hsync & ~HSYNC_I & hSyncReg) begin
			hSyncReg <= 0;
			if(hSyncCount > 7*4) hs4 <= 0;
			if((hSyncCount >= 4*4-1) && (hSyncCount < 6*4-1)) begin
				if(hSyncCount == 4*4-1) hs4 <= 1;
				shift <= 1;
			end
		end

		if(hSyncCount == 2*4) begin
			HSYNC_O <= 1;
			shift <= 0;
			old_vsync <= VSYNC_I;
			
			if(~&vSyncFlt) vSyncFlt <= vSyncFlt + 1'd1;

			if(VSYNC_I) begin
				if(~old_vsync && (vSyncFlt > VFLT_SZ)) begin
					vSyncCount = 0;
					vSyncFlt <= 0;
				end
				else if(~&vSyncCount) vSyncCount = vSyncCount + 1'd1;
			end
			
			if(vSyncCount == 1) VSYNC_O <= 1;
			if(!vSyncCount || (vSyncCount == 3)) VSYNC_O <= 0;
		end

		//force VSYNC disable earlier
		if(~VSYNC_I) VSYNC_O <= 0;

		if(hSyncCount == 6*4) HSYNC_O <= 0;
	end
end

endmodule
