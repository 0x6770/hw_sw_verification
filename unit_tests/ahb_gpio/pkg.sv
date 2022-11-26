package pkg;

  class environment;
    // instantiate driver, monitor, scoreboard and generator
    ahb_pkg::monitor monitor;
    ahb_pkg::driver driver;
    ahb_pkg::scoreboard scoreboard;
    ahb_pkg::generator generator;

    mailbox drv_box;
    mailbox scb_expected_box;
    mailbox scb_observed_box;
    int num_transactions;

    // create event to indicate completion of transaction generation
    event gen_finished;

    // interface
    virtual ahb_if ahb_vif;
    virtual gpio_if gpio_vif;

    // constructor
    function new(virtual ahb_if ahb_vif, virtual gpio_if gpio_vif, int num_transactions, bit error);
      $display("[ENVIRONMENT] : constructing new environment");
      this.ahb_vif = ahb_vif;
      this.gpio_vif = gpio_vif;
      this.num_transactions = num_transactions;
      this.gpio_vif.PARITY_SEL = $urandom() % 2 == 1;

      // initialise mailbox
      drv_box = new();
      scb_expected_box = new();
      scb_observed_box = new();
      // initialise testbench components
      generator = new(.box(drv_box), .cnt(num_transactions), .finished(gen_finished));
      driver = new(.vif(ahb_vif), .drv_box(drv_box));
      monitor = new(
          .vif(ahb_vif),
          .scb_observed_box(scb_observed_box),
          .scb_expected_box(scb_expected_box),
          .parity_sel(this.gpio_vif.PARITY_SEL)
      );
      scoreboard = new(.scb_observed_box(scb_observed_box), .scb_expected_box(scb_expected_box));
    endfunction : new

    task pre_test();
      driver.reset();
    endtask : pre_test

    task test();
      fork
        generator.run();
        driver.run();
        monitor.run();
        scoreboard.run();
      join_any
    endtask : test

    task post_test();
      wait (gen_finished.triggered);
      wait (num_transactions == scoreboard.num_items_observed);
    endtask : post_test

    // run task
    task run;
      pre_test();
      test();
      post_test();
      $finish;
    endtask

  endclass : environment

endpackage
