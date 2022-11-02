interface gpio_if;
  logic [15:0] GPIO_IN;
  logic [15:0] GPIO_OUT;

  modport driver(output GPIO_IN);
  modport monitor(input GPIO_IN, GPIO_OUT);
  modport dut(output GPIO_OUT);
endinterface
