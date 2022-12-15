package pkg;

  // Scoreboard
  class scoreboard;
    mailbox         scb_expected_box;
    mailbox         scb_observed_box;
    virtual err_if  err_vif;
    virtual gpio_if gpio_vif;
    event           data_written;

    ahb_pkg::transaction  expected_queue[$];
    gpio_pkg::transaction observed_queue[$];

    int num_items_observed = 0;

    function new(mailbox scb_expected_box, mailbox scb_observed_box, virtual err_if err_vif,
                 virtual gpio_if gpio_vif, event data_written);
      this.scb_expected_box = scb_expected_box;
      this.scb_observed_box = scb_observed_box;
      this.data_written     = data_written;
      this.gpio_vif         = gpio_vif;
      this.err_vif          = err_vif;
    endfunction

    task receive_expected_items();
      forever begin
        ahb_pkg::transaction item;
        scb_expected_box.get(item);
`ifdef DEBUG
        item.display("SCOREBOARD AHB");
`endif
        expected_queue.push_front(item);
      end
    endtask

    task receive_observed_items();
      forever begin
        gpio_pkg::transaction item;
        scb_observed_box.get(item);
`ifdef DEBUG
        item.display("SCOREBOARD GPIO");
`endif
        observed_queue.push_front(item);
      end
    endtask

    task check();
      forever begin
        gpio_pkg::transaction item;
        ahb_pkg::transaction  expected_item;
        @(data_written);
        @(posedge gpio_vif.monitor.clk);
        @(posedge gpio_vif.monitor.clk);
        item          = observed_queue[0];
        expected_item = expected_queue[0];

        $display("============================== [%d]", num_items_observed);
        $display("expected:   0x%4h observed:   0x%4h", expected_item.data, item.data);
        $display("expected:   0b%h    observed:   0b%h", expected_item.parity, item.parity);
        // $display("parity_sel: 0b%h    parity_sel: 0b%h", expected_item.parity_sel, item.parity_sel);
`ifdef DEBUG
        item.display("SCOREBOARD");
        expected_item.display("SCOREBOARD");
`endif
        assert (expected_item.data === item.data);
        assert (expected_item.parity === item.parity);
        // assert (expected_item.parity === (err_vif.error ? ~item.parity : item.parity));
        assert (err_vif.error === gpio_vif.PARITYERR);
        num_items_observed++;
      end
    endtask

    task run();
      fork
        receive_observed_items();
        receive_expected_items();
        check();
      join_any
    endtask
  endclass : scoreboard

  class environment;
    // instantiate driver, monitor, scoreboard and generator
    ahb_pkg::wdata_monitor ahb_wdata_monitor;
    ahb_pkg::rdata_monitor ahb_rdata_monitor;
    ahb_pkg::driver        driver;
    ahb_pkg::generator     generator;
    gpio_pkg::in_monitor   gpio_in_monitor;
    gpio_pkg::out_monitor  gpio_out_monitor;
    scoreboard             scoreboard;

    mailbox                drv_box;
    mailbox                scb_ahb_expected_box;
    mailbox                scb_ahb_observed_box;
    mailbox                scb_gpio_expected_box;
    mailbox                scb_gpio_observed_box;
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
      this.gpio_vif.PARITYSEL = $urandom() % 2 == 1;
      this.err_vif            = err_vif;

      // initialise mailbox
      drv_box               = new();
      scb_ahb_expected_box  = new();
      scb_ahb_observed_box  = new();
      scb_gpio_expected_box = new();
      scb_gpio_observed_box = new();
      // initialise testbench components
      generator = new(.box(drv_box), .cnt(num_transactions), .finished(gen_finished));
      driver = new(.vif(ahb_vif), .drv_box(drv_box), .err_vif(err_vif));
      ahb_wdata_monitor = new(
        .vif(ahb_vif),
        .scb_box(scb_ahb_expected_box),
        .parity_sel(this.gpio_vif.PARITYSEL),
        .data_written(data_written)
      );
      ahb_rdata_monitor = new(
        .vif(ahb_vif),
        .scb_box(scb_ahb_observed_box),
        .parity_sel(this.gpio_vif.PARITYSEL)
      );
      gpio_in_monitor = new(
        .vif(gpio_vif.monitor),
        .scb_box(scb_gpio_expected_box)
      );
      gpio_out_monitor = new(
        .vif(gpio_vif.monitor),
        .scb_box(scb_gpio_observed_box)
      );
      scoreboard = new(
        .scb_expected_box(scb_ahb_expected_box),
        .scb_observed_box(scb_gpio_observed_box),
        .data_written(data_written),
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
        ahb_wdata_monitor.run();
        ahb_rdata_monitor.run();
        gpio_in_monitor.run();
        gpio_out_monitor.run();
        scoreboard.run();
      join_any
    endtask : test

    task post_test();
      $display("enter post test");
      wait (gen_finished.triggered);
      $display("finish post test 1");
      wait (scoreboard.num_items_observed >= num_transactions);
      $display("finish post test 2");
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
