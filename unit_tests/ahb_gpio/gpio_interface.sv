interface gpio_if;
  logic [16:0] GPIO_IN;
  logic [16:0] GPIO_OUT;
  logic PARITY_SEL;
  logic PARITY_ERR;

  modport driver(output GPIO_IN, PARITY_SEL);
  modport monitor(input GPIO_IN, GPIO_OUT, PARITY_SEL, PARITY_ERR);
  modport dut(input GPIO_IN, input PARITY_SEL, output GPIO_OUT, output PARITY_ERR);
endinterface
