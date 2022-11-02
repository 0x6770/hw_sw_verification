class AHB_environment;
  // instantiate driver, monitor, scoreboard and generator
  AHB_monitor monitor;
  AHB_driver driver;
  AHB_scoreboard scoreboard;
  AHB_generator generator;

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
  function new(virtual ahb_if ahb_vif, virtual gpio_if gpio_vif, int num_transactions);
    $display("[ENVIRONMENT] : constructing new environment");
    this.ahb_vif = ahb_vif;
    this.gpio_vif = gpio_vif;
    this.num_transactions = num_transactions;
    // initialise mailbox
    drv_box = new();
    scb_expected_box = new();
    scb_observed_box = new();
    // initialise
    generator = new(.box(drv_box), .cnt(num_transactions), .finished(gen_finished));
    driver = new(.vif(ahb_vif), .drv_box(drv_box), .scb_expected_box(scb_expected_box));
    monitor = new(.scb_observed_box(scb_observed_box));
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
    wait (num_transactions == driver.num_transactions_received);
  endtask : post_test

  // run task
  task run;
    pre_test();
    test();
    post_test();
    $finish;
  endtask
endclass : AHB_environment
