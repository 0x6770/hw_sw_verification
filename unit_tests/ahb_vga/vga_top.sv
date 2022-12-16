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

module vga_top;
    bit                  clk;
    initial begin                 // Create a free-running clock
       clk = 0;
       forever #10 clk = ! clk;
    end

  vga_if vga_if (clk);           // Interface with clocking block
  DLS_TOP DUT (vga_if);
  vga_tb VGA_tb (vga_if);

endmodule