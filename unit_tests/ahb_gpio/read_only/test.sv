program test #(
    parameter int NUM_TRANSACTIONS = 10
) (
    ahb_if ahb_if,
    gpio_if gpio_if,
    err_if err_if
);
  // declaring environment instance
  pkg::environment env;

  initial begin
    $display("[TEST] : start testing");
    // creating environment
    env = new(.ahb_vif(ahb_if), .gpio_vif(gpio_if), .err_vif(err_if), .num_transactions(NUM_TRANSACTIONS));
    env.run();
  end
endprogram : test
