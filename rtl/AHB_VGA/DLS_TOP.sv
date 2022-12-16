interface vga_if (
    input logic HCLK
);
  logic        HRESETn; //reset signal
  logic        HSEL_VGA;  // slave select signal
  logic        HREADY;  // previous transfer has finished on the bus [multiplexor to master/slave]
  logic [31:0] HADDR;  // address
  logic [ 1:0] HTRANS;  // transfer type, 2'b10 (non-sequential) for single transfer
  logic        HWRITE;  // transfer direction
  logic [31:0] HWDATA;  // write data bus
  logic        HREADYOUT_VGA;  // slave transfer complete
  logic [31:0] HRDATA_VGA;  // read data bus
  logic        DLS_ERROR;
  logic        HSYNC;
  logic        VSYNC;
  logic [7:0] RGB;
  logic        HSYNC_REDUN;
  logic        VSYNC_REDUN;
  logic [7:0] RGB_REDUN;


  modport DUT(
      // global
      input HCLK,
      input HRESETn,
      // select
      input HSEL_VGA,
      // address and control
      input HADDR,
      input HWRITE,
      input HTRANS,
      // data
      input HWDATA,
      output HRDATA_VGA,
      // transfer response
      input HREADY,
      output HREADYOUT_VGA,
      output HSYNC,
      output VSYNC,
      output RGB,
      output HSYNC_REDUN,
      output VSYNC_REDUN,
      output RGB_REDUN,
      output DLS_ERROR
  );

clocking cb @(posedge HCLK);
 input HREADYOUT_VGA, HRDATA_VGA, HSYNC, VSYNC, RGB;
 output HSEL_VGA, HWRITE, HADDR, HREADY, HWDATA, HTRANS;
endclocking

  modport TEST(
      // global
      output HRESETn,
      clocking cb,
      input DLS_ERROR
  
  );
endinterface

module DLS_TOP
(vga_if.DUT vga_if);

//AHB outputs from secondary
wire [31:0] 	HRDATA_VGA_REDUN;
wire            HREADYOUT_VGA_REDUN;

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

    //   assert_DLS_ERROR: 
    //   assert property(     
    //     @(posedge vga_if.HCLK) disable iff (!vga_if.HRESETn)
    //     (!vga_if.DLS_ERROR) |-> (vga_if.RGB == vga_if.RGB_REDUN) && (vga_if.HSYNC == vga_if.HSYNC_REDUN) && (vga_if.VSYNC == vga_if.VSYNC_REDUN));
 
 endmodule