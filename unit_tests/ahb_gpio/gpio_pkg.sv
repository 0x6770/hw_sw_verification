package gpio_pkg;

  // Transaction for GPIO
  class transaction;
    rand logic [15:0] data;
    rand logic        parity;
    logic             real_parity;
    logic             parity_sel;

    function void display(string tag = "");
      $display("T=%t [%s]", $time, tag);
      $display("data:        %h", data);
      $display("parity:      %h", parity);
      $display("parity_sel:  %h", parity_sel);
      $display("real_parity: %h", real_parity);
    endfunction : display

    // constructor
    function new();
    endfunction : new

    function void calc_parity();
      real_parity = parity_sel ? ~(^data) : ^data;
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

  class in_monitor;
    virtual gpio_if vif;
    mailbox         scb_box;

    function new(virtual gpio_if vif, mailbox scb_box);
      this.vif     = vif;
      this.scb_box = scb_box;
    endfunction

    task run();
      forever begin
        @(posedge vif.clk);
        begin
          transaction item = new();
          item.data       = vif.GPIOIN[15:0];
          item.parity     = vif.GPIOIN[16];
          item.parity_sel = vif.PARITYSEL;
          item.calc_parity();
          scb_box.put(item);
        end
      end
    endtask
  endclass

  class out_monitor;
    virtual gpio_if vif;
    mailbox         scb_box;

    function new(virtual gpio_if vif, mailbox scb_box);
      this.vif     = vif;
      this.scb_box = scb_box;
    endfunction

    task run();
      transaction item;
      forever begin
        @(posedge vif.clk);
        item = new();
        item.data       = vif.GPIOOUT[15:0];
        item.parity     = vif.GPIOOUT[16];
        item.parity_sel = vif.PARITYSEL;
        item.calc_parity();
        scb_box.put(item);
      end
    endtask
  endclass

endpackage : gpio_pkg
