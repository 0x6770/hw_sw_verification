interface gpio_if;
  logic clk;
  logic reset_n;
  logic [16:0] GPIOIN;
  logic [16:0] GPIOOUT;
  logic PARITYSEL;
  logic PARITYERR;

  modport driver(output GPIOIN, PARITYSEL);
  modport monitor(input GPIOIN, GPIOOUT, PARITYSEL, PARITYERR);
  modport dut(input GPIOIN, input PARITYSEL, output GPIOOUT, output PARITYERR);
endinterface

interface err_if;
  bit error;
endinterface
