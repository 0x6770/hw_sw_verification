module tbench_top;
  //clock and reset signal declaration
  bit clk;
  bit reset_n;

  //clock generation
  always #5 clk = ~clk;

  //reset Generation
  initial begin
    reset_n = 0;
    #50 reset_n = 1;
  end

  //creatinng instance of interface, inorder to connect DUT and testcase
  ahb_if ahb_if (
    .clk    (clk),
    .reset_n(reset_n)
  );
  gpio_if gpio_if (
    .clk    (clk),
    .reset_n(reset_n)
  );

  //Testcase instance, interface handle is passed to test as an argument
  test #(
      .NUM_TRANSACTIONS(500)
  ) t1 (
      .ahb_if (ahb_if),
      .gpio_if(gpio_if)
  );

  //DUT instance, interface signals are connected to the DUT ports
  AHBGPIO DUT (
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
      .GPIOIN   (gpio_if.GPIOIN),
      .GPIOOUT  (gpio_if.GPIOOUT),
      // parity
      .PARITYERR(gpio_if.PARITYERR),
      .PARITYSEL(gpio_if.PARITYSEL)   // 1'b1 ? odd parity : even parity
  );

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
