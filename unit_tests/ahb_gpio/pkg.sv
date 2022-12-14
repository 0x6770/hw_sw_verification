package pkg;

  class environment;
    // instantiate driver, monitor, scoreboard and generator
    ahb_pkg::monitor    ahb_monitor;
    gpio_pkg::monitor   gpio_monitor;
    ahb_pkg::driver     driver;
    ahb_pkg::scoreboard scoreboard;
    ahb_pkg::generator  generator;

    mailbox             drv_box;
    mailbox             scb_ahb_expected_box;
    mailbox             scb_ahb_observed_box;
    mailbox             scb_gpio_expected_box;
    mailbox             scb_gpio_observed_box;
    int                 num_transactions;

    // create event to indicate completion of transaction generation
    event               gen_finished;

    // interface
    virtual ahb_if      ahb_vif;
    virtual gpio_if     gpio_vif;
    virtual err_if      err_vif;

    // constructor
    function new(virtual ahb_if ahb_vif, virtual gpio_if gpio_vif, virtual err_if err_vif,
                 int num_transactions);
      $display("[ENVIRONMENT] : constructing new environment");
      this.ahb_vif = ahb_vif;
      this.gpio_vif = gpio_vif;
      this.num_transactions = num_transactions;
      this.gpio_vif.PARITYSEL = $urandom() % 2 == 1;
      this.err_vif = err_vif;

      // initialise mailbox
      drv_box = new();
      scb_ahb_expected_box = new();
      scb_ahb_observed_box = new();
      scb_gpio_expected_box = new();
      scb_gpio_observed_box = new();
      // initialise testbench components
      generator = new(.box(drv_box), .cnt(num_transactions), .finished(gen_finished));
      driver = new(.vif(ahb_vif), .drv_box(drv_box), .err_vif(err_vif));
      ahb_monitor = new(
          .vif(ahb_vif),
          .scb_observed_box(scb_ahb_observed_box),
          .scb_expected_box(scb_ahb_expected_box),
          .parity_sel(this.gpio_vif.PARITYSEL)
      );
      gpio_monitor = new(
          .vif(gpio_vif),
          .scb_observed_box(scb_gpio_observed_box)
      );  
      scoreboard = new(
          .scb_observed_box(scb_ahb_observed_box),
          .scb_expected_box(scb_ahb_expected_box),
          .err_vif(err_vif),
          .gpio_vif(gpio_vif)
      );
    endfunction : new

    task pre_test();
      driver.reset();
    endtask : pre_test

    task test();
      fork
        generator.run();
        driver.run();
        ahb_monitor.run();
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
