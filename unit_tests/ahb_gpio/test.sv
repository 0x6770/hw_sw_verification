program test #(
    parameter int NUM_TRANSACTIONS = 10
) (
    ahb_if  ahb_if,
    gpio_if gpio_if
);
  // declaring environment instance
  pkg::environment env;

  initial begin
    $display("[TEST] : start testing");
    // creating environment
    env = new(ahb_if, gpio_if, NUM_TRANSACTIONS);

    env.run();
  end
endprogram : test
