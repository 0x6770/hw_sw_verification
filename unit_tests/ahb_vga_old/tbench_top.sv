module tbench_top;
  //clock and reset signal declaration
  bit clk;
  bit reset_n;

  //clock generation: for VGA we are using an 25MHz clk
  always #20 clk = ~clk;

  //reset Generation
  initial begin
    reset_n = 0;
    #20 reset_n = 1;
  end

  //creatinng instance of interface, inorder to connect DUT and testcase
  ahb_if ahb_if (
      .clk    (clk),
      .reset_n(reset_n)
  );

  vga_if vga_if ();

  //Testcase instance, interface handle is passed to test as an argument
  test #(20) unit_level_test (
      .ahb_if (ahb_if),
      .vga_if(vga_if)
  );

  //DUT instance, interface signals are connected to the DUT ports
  AHBVGA DUT (
      .HCLK     (ahb_if.clk),
      .HRESETn  (ahb_if.reset_n),
      // select
      .HSEL     (ahb_if.sel),
      // address and control
      .HADDR    (ahb_if.addr),
      .HTRANS   (ahb_if.trans),
      .HWRITE   (ahb_if.write),
      .HREADY   (ahb_if.ready),
      .HREADYOUT(ahb_if.readyout),
      // data
      .HWDATA   (ahb_if.wdata),
      .HRDATA   (ahb_if.rdata),
      // GPIO I/O
      .HSYNC   (vga_if.HSYNC),
      .VSYNC  (vga_if.VSYNC),
      .RGB   (vag_if.RGB)
);

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
