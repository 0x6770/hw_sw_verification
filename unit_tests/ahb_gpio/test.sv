program test #(
    parameter int NUM_TRANSACTIONS = 10,
    parameter bit PARITY_SEL = 1'b1
) (
    ahb_if ahb_if,
    gpio_if gpio_if,
    input error
);
  // declaring environment instance
  pkg::environment env;

  initial begin
    $display("[TEST] : start testing");
    // creating environment
    env = new(
        .ahb_vif(ahb_if),
        .gpio_vif(gpio_if),
        .num_transactions(NUM_TRANSACTIONS),
        .parity_sel(PARITY_SEL),
        .error(error)
    );

    env.run();
  end
endprogram : test
