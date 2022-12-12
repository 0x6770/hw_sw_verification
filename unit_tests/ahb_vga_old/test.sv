program test #(
    parameter int NUM_TRANSACTIONS = 10
) (
    ahb_if  ahb_if,
    vga_if vga_if
);
  // declaring environment instance
  pkg::environment env;

  initial begin
    $display("[TEST] : start testing");
    // creating environment
    env = new(ahb_if, vga_if, NUM_TRANSACTIONS);
    env.run();
  end
endprogram : test
