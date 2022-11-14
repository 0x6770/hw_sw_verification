module tbench_top;
  //clock and reset signal declaration
  bit clk;
  bit reset_n;

  //clock generation
  always #5 clk = ~clk;

  //reset Generation
  initial begin
    reset_n = 0;
    #5 reset_n = 1;
  end

  //creatinng instance of interface, inorder to connect DUT and testcase
  ahb_if ahb_if (
      .clk    (clk),
      .reset_n(reset_n)
  );

  gpio_if gpio_if ();

  //Testcase instance, interface handle is passed to test as an argument
  test #(20) t1 (
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
      .GPIOIN   (gpio_if.GPIO_IN),
      .GPIOOUT  (gpio_if.GPIO_OUT),
      // parity
      .PARITYERR(),
      .PARITYSEL(1'b0)               // 1'b1 ? odd parity : even parity
  );

  loopback u0 (
      .clk     (ahb_if.clk),
      .reset_n (ahb_if.reset_n),
      .GPIO_IN (gpio_if.GPIO_IN),
      .GPIO_OUT(gpio_if.GPIO_OUT)
  );

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
