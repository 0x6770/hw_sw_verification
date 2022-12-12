module DLS_TOP
(vga_if.DUT vga_if);

//AHB outputs from secondary
wire [31:0] 	HRDATA_VGA_REDUN;
wire            HREADYOUT_VGA_REDUN;

// //VGA outputs from primary
// wire   HSYNC;
// wire   VSYNC;
// wire  [7:0] RGB;

// //VGA outputs from secondary
// wire   HSYNC_REDUN;
// wire   VSYNC_REDUN;
// wire  [7:0] RGB_REDUN;

// AHBLite VGA Peripheral
AHBVGA uAHBVGA_Primary (
    .HCLK(vga_if.HCLK), 
    .HRESETn(vga_if.HRESETn), 
    .HADDR(vga_if.HADDR), 
    .HWDATA(vga_if.HWDATA), 
    .HREADY(vga_if.HREADY), 
    .HWRITE(vga_if.HWRITE), 
    .HTRANS(vga_if.HTRANS), 
    .HSEL(vga_if.HSEL_VGA), 
    //AHB outputs
    .HRDATA(vga_if.HRDATA_VGA), 
    .HREADYOUT(vga_if.HREADYOUT_VGA),
    //VGA Periferal outputs 
    .HSYNC(vga_if.HSYNC), 
    .VSYNC(vga_if.VSYNC), 
    .RGB(vga_if.RGB)
    );

    // AHBLite VGA Peripheral
AHBVGA_r uAHBVGA_Secondary (
    .HCLK(vga_if.HCLK), 
    .HRESETn(vga_if.HRESETn), 
    .HADDR(vga_if.HADDR), 
    .HWDATA(vga_if.HWDATA), 
    .HREADY(vga_if.HREADY), 
    .HWRITE(vga_if.HWRITE), 
    .HTRANS(vga_if.HTRANS), 
    .HSEL(vga_if.HSEL_VGA), 
    //AHB outputs
    .HRDATA(HRDATA_VGA_REDUN), 
    .HREADYOUT(HREADYOUT_VGA_REDUN), 
    //VGA Periferal outputs
    .HSYNC(vga_if.HSYNC_REDUN), 
    .VSYNC(vga_if.VSYNC_REDUN), 
    .RGB(vga_if.RGB_REDUN)
    );

COMP uCOMP (
    //AHB outputs
    .HRDATA_VGA(vga_if.HRDATA_VGA), 
    .HREADYOUT_VGA(vga_if.HREADYOUT_VGA),
    //VGA Periferal outputs 
    .HSYNC(vga_if.HSYNC), 
    .VSYNC(vga_if.VSYNC), 
    .RGB(vga_if.RGB),

    //AHB outputs
    .HRDATA_VGA_REDUN(HRDATA_VGA_REDUN), 
    .HREADYOUT_VGA_REDUN(HREADYOUT_VGA_REDUN), 
    //VGA Periferal outputs
    .HSYNC_REDUN(vga_if.HSYNC_REDUN), 
    .VSYNC_REDUN(vga_if.VSYNC_REDUN), 
    .RGB_REDUN(vga_if.RGB_REDUN),

    .DLS_ERROR(vga_if.DLS_ERROR)
);

endmodule