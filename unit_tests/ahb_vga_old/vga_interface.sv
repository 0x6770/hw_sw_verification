interface vga_if;
  logic HSYNC;
  logic VSYNC;
  logic [7:0] RGB;

  //modport driver(output GPIO_IN);
  //modport monitor(input GPIO_IN, GPIO_OUT);
  modport dut(output HSYNC, VSYNC, RGB);
  
endinterface
