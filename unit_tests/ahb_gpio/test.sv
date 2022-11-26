program test #(
    parameter int NUM_TRANSACTIONS = 10
    // parameter bit PARITY_SEL = 1'b1
) (
    ahb_if ahb_if,
    gpio_if gpio_if,
    input bit parity_sel,
    input bit error
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
        .error(error)
    );

    env.run();
  end
endprogram : test
