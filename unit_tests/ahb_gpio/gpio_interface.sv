interface gpio_if (
    input logic clk,
    input logic reset_n
);
  logic [16:0] GPIOIN;
  logic [16:0] GPIOOUT;
  logic PARITYSEL;
  logic PARITYERR;

  modport driver(input clk, input reset_n, output GPIOIN, output PARITYSEL);
  modport monitor(
      input clk,
      input reset_n,
      input GPIOIN,
      input GPIOOUT,
      input PARITYSEL,
      input PARITYERR
  );
  modport dut(
      input clk,
      input reset_n,
      input GPIOIN,
      input PARITYSEL,
      output GPIOOUT,
      output PARITYERR
  );
endinterface

interface err_if;
  bit error;
endinterface
