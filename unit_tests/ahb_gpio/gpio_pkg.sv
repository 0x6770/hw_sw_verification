package gpio_pkg;

  // Transaction for GPIO
  class transaction;
    static int        count        = 0;
    int               id;

    rand logic [15:0] data;
    rand logic        parity;
    rand logic        parity_sel;
    logic             real_parity;

    function void display(string tag = "");
      $display("T=%t [%s]", $time, tag);
      $display("id:          %h", id);
      $display("data:        %h", data);
      $display("parity:      %h", parity);
      $display("parity_sel:  %h", parity_sel);
      $display("real_parity: %h", real_parity);
    endfunction : display

    // constructor
    function new();
      id = count++;
      real_parity = parity_sel ? ~(^data) : ^data;
    endfunction : new

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
      vif.DATA_IN <= 'h0;
      wait (vif.reset_n);
    endtask

    task update(transaction item);
      @(posedge vif.clk);
      vif.DATA_IN <= item.data;
      num_items_received++;
    endtask

  endclass : driver

  class monitor;
    virtual gpio_if vif;
    mailbox scb_observed_box;

    function new(mailbox scb_observed_box);
      this.scb_observed_box = scb_observed_box;
    endfunction

    task run();
    endtask
  endclass

endpackage : gpio_pkg
