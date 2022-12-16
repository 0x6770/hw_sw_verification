module COMP (
//AHB outputs from primary
input wire [31:0] 	HRDATA_VGA,
input wire            HREADYOUT_VGA,

input wire [31:0] 	HRDATA_VGA_REDUN,
input wire            HREADYOUT_VGA_REDUN,

//VGA outputs from primary
input wire   HSYNC,
input wire   VSYNC,
input wire [7:0] RGB,

//VGA outputs from secondary
input wire   HSYNC_REDUN,
input wire   VSYNC_REDUN,
input wire [7:0] RGB_REDUN,

output DLS_ERROR
);

wire AHB_SAME = (HRDATA_VGA === HRDATA_VGA_REDUN) && (HREADYOUT_VGA === HREADYOUT_VGA_REDUN);
wire VGA_SAME = (HSYNC === HSYNC_REDUN) && (VSYNC === VSYNC_REDUN) && (RGB === RGB_REDUN);

assign DLS_ERROR = ~(AHB_SAME && VGA_SAME);

endmodule

