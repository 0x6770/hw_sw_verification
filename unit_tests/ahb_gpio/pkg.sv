package pkg;

  // Scoreboard
  class scoreboard;
    mailbox scb_expected_box;
    mailbox scb_observed_box;
    virtual err_if err_vif;
    virtual gpio_if gpio_vif;

    ahb_pkg::transaction expected_queue[$];

    int num_items_observed = 0;

    function new(mailbox scb_expected_box, mailbox scb_observed_box, virtual err_if err_vif,
                 virtual gpio_if gpio_vif);
      this.scb_expected_box = scb_expected_box;
      this.scb_observed_box = scb_observed_box;
      this.gpio_vif         = gpio_vif;
      this.err_vif          = err_vif;
    endfunction

    task receive_expected_items();
      forever begin
        ahb_pkg::transaction item;
        scb_expected_box.get(item);
`ifdef DEBUG
        item.display("SCOREBOARD");
`endif
        expected_queue.push_back(item);
      end
    endtask

    task receive_observed_items();
      forever begin
        ahb_pkg::transaction item, expected_item;
        scb_observed_box.get(item);
        expected_item = expected_queue.pop_front();
        $display("============================== [%d]", num_items_observed);
        $display("expected:   0x%4h observed:   0x%4h", expected_item.data, item.data);
        $display("expected:   0b%h    observed:   0b%h", expected_item.parity, item.parity);
        $display("parity_sel: 0b%h    parity_sel: 0b%h", expected_item.parity_sel, item.parity_sel);
`ifdef DEBUG
        item.display("SCOREBOARD");
        expected_item.display("SCOREBOARD");
`endif
        assert (expected_item.data === item.data);
        assert (expected_item.parity === (err_vif.error ? ~item.parity : item.parity));
        assert (err_vif.error == gpio_vif.PARITYERR);
        num_items_observed++;
      end
    endtask

    task run();
      fork
        receive_observed_items();
        receive_expected_items();
      join
    endtask
  endclass : scoreboard

  class environment;
    // instantiate driver, monitor, scoreboard and generator
    ahb_pkg::monitor    ahb_monitor;
    ahb_pkg::driver     driver;
    ahb_pkg::generator  generator;
    gpio_pkg::monitor   gpio_monitor;
    scoreboard scoreboard;

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
