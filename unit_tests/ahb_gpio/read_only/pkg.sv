package pkg;

  // Scoreboard
  class scoreboard;
    mailbox         scb_expected_box;
    mailbox         scb_observed_box;
    virtual err_if  err_vif;
    virtual gpio_if gpio_vif;

    int num_items_observed = 0;

    function new(mailbox scb_expected_box, mailbox scb_observed_box,
                 virtual err_if err_vif, virtual gpio_if gpio_vif);
      this.scb_expected_box = scb_expected_box;
      this.scb_observed_box = scb_observed_box;
      this.gpio_vif         = gpio_vif;
      this.err_vif          = err_vif;
    endfunction

    task run();
      ahb_pkg::transaction  item;
      gpio_pkg::transaction expected_item;
      forever begin
        scb_expected_box.get(expected_item);
        scb_observed_box.get(item);

        $display("============================== [%d]",  num_items_observed);
        $display("expected:   0x%4h observed:   0x%4h",  expected_item.data,       item.data);
        $display("expected:   0b%h    observed:   0b%h", expected_item.parity,     item.parity);
        $display("parity_sel: 0b%h    parity_sel: 0b%h", expected_item.parity_sel, item.parity_sel);
`ifdef DEBUG
        item.display("SCOREBOARD");
        expected_item.display("SCOREBOARD");
`endif
        assert (expected_item.data   === item.data);
        assert (expected_item.parity === item.parity);
        // assert (expected_item.parity === (err_vif.error ? ~item.parity : item.parity));
        assert (err_vif.error === gpio_vif.PARITYERR);
        num_items_observed++;
      end
    endtask

  endclass : scoreboard

  class environment;
    // instantiate driver, monitor, scoreboard and generator
    ahb_pkg::wdata_monitor ahb_wdata_monitor;
    ahb_pkg::rdata_monitor ahb_rdata_monitor;
    ahb_pkg::driver        ahb_driver;
    gpio_pkg::generator    gpio_generator;
    gpio_pkg::driver       gpio_driver;
    gpio_pkg::in_monitor   gpio_in_monitor;
    gpio_pkg::out_monitor  gpio_out_monitor;
    scoreboard             scoreboard;

    mailbox                ahb_drv_box;
    mailbox                ahb_scb_expected_box;
    mailbox                ahb_scb_observed_box;
    mailbox                gpio_drv_box;
    mailbox                gpio_scb_expected_box;
    mailbox                gpio_scb_observed_box;
    int                    num_transactions;

    // create event to indicate completion of transaction generation
    event                  gen_finished;
    event                  data_written;

    // interface
    virtual ahb_if         ahb_vif;
    virtual gpio_if        gpio_vif;
    virtual err_if         err_vif;

    // constructor
    function new(virtual ahb_if ahb_vif, virtual gpio_if gpio_vif, virtual err_if err_vif, int num_transactions);
      $display("[ENVIRONMENT] : constructing new environment");
      this.ahb_vif            = ahb_vif;
      this.gpio_vif           = gpio_vif;
      this.num_transactions   = num_transactions;
      this.gpio_vif.PARITYSEL = $urandom_range(0, 1);
      this.err_vif            = err_vif;

      // initialise mailbox
      ahb_drv_box           = new();
      ahb_scb_expected_box  = new();
      ahb_scb_observed_box  = new();
      gpio_drv_box          = new();
      gpio_scb_expected_box = new();
      gpio_scb_observed_box = new();
      // initialise testbench components
      gpio_generator        = new(.box(gpio_drv_box), .cnt(num_transactions), .finished(gen_finished));
      ahb_driver            = new(.vif( ahb_vif.driver), .drv_box( ahb_drv_box), .err_vif(err_vif));
      gpio_driver           = new(.vif(gpio_vif.driver), .drv_box(gpio_drv_box), .err_vif(err_vif), .data_written(data_written));
      ahb_rdata_monitor = new(
        .vif(ahb_vif),
        .scb_box(ahb_scb_observed_box),
        .parity_sel(this.gpio_vif.PARITYSEL),
        .data_written(data_written)
      );
      gpio_in_monitor = new(
        .vif(gpio_vif.monitor),
        .scb_box(gpio_scb_expected_box),
        .data_written(data_written)
      );
      scoreboard = new(
        .scb_expected_box(gpio_scb_expected_box),
        .scb_observed_box(ahb_scb_observed_box),
        .err_vif(err_vif),
        .gpio_vif(gpio_vif)
      );
    endfunction : new

    task pre_test();
      fork
        ahb_driver.reset();
        gpio_driver.reset();
      join_any
      // change GPIO to read mode
      // ahb_driver.switch_mode(0);
    endtask : pre_test

    task test();
      fork
        gpio_generator.run();
        gpio_driver.run();
        gpio_in_monitor.run();
        ahb_driver.keep_read();
        ahb_rdata_monitor.run();
        scoreboard.run();
      join_any
    endtask : test

    task post_test();
      wait (gen_finished.triggered);
      wait (scoreboard.num_items_observed == num_transactions);
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
