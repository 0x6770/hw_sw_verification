package gpio_pkg;

  // Transaction for GPIO
  class transaction;
    rand logic [15:0] data;
    rand logic        parity;
    logic             real_parity;

    function void display(string tag = "");
      $display("T=%t [%s]", $time, tag);
      $display("data:        %h", data);
      $display("parity:      %h", parity);
      $display("real_parity: %h", real_parity);
    endfunction : display

    // constructor
    function new();
    endfunction : new

    function void calc_parity(PARITYSEL);
      real_parity = PARITYSEL ? ~(^data) : ^data;
    endfunction

  endclass : transaction

  class driver;
    virtual gpio_if vif;
    // mailbox drv_box;
    int num_items_received = 0;

    function new(virtual gpio_if vif);
      this.vif = vif;
      // this.drv_box = drv_box;
    endfunction

    task reset();
      wait (!vif.reset_n);
      vif.GPIOIN <= 'h0;
      wait (vif.reset_n);
    endtask

    task update(transaction item);
      @(posedge vif.clk);
      vif.GPIOIN <= item.data;
      num_items_received++;
    endtask

  endclass : driver

  class monitor;
    virtual gpio_if vif;
    mailbox         scb_observed_box;

    function new(virtual gpio_if vif, mailbox scb_observed_box);
      this.vif              = vif;
      this.scb_observed_box = scb_observed_box;
    endfunction

    task run();
      forever begin
        @(posedge vif.clk);
        begin
          transaction item = new();
          item.data   = vif.GPIOOUT[15:0];
          item.parity = vif.GPIOOUT[16];
          item.calc_parity(vif.PARITYSEL);
        end
      end
    endtask
  endclass

endpackage : gpio_pkg
