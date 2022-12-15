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

  class generator;
    rand transaction item;
    mailbox drv_box;      // send items to driver
    int repeat_cnt = 10;  // generate 10 transactions by default
    event finished;

    // constructor
    function new(mailbox box, int cnt, event finished);
      this.drv_box    = box;  // getting driver mailbox form env
      this.repeat_cnt = cnt;
      this.finished   = finished;
    endfunction

    // create and randomize transactions
    // put transactions into mailbox
    // call finished at the end
    task run();
      repeat (repeat_cnt) begin
        item = new();
        if (!item.randomize()) $fatal("[AHB Generator] : transaction randomization failed");
        drv_box.put(item);
      end
      ->finished;
      $display("generated all transactions");
    endtask
  endclass : generator

  class driver;
    virtual gpio_if vif;
    virtual err_if  err_vif;
    mailbox         drv_box;
    int             num_items_received = 0;

    function new(virtual gpio_if vif, virtual err_if err_vif, mailbox drv_box);
      this.vif     = vif;
      this.err_vif = err_vif;
      this.drv_box = drv_box;
    endfunction

    task reset();
      wait (!vif.reset_n);
      vif.GPIOIN <= 'h0;
      wait (vif.reset_n);
    endtask

    task write(transaction item);
      @(posedge vif.clk);
      vif.GPIOIN <= item.data;
      num_items_received++;
    endtask

    task run();
      @(posedge vif.clk);
      $display("T=%t [GPIO DRIVER] : starting", $time);
      
      forever begin
        transaction item;
        $display("T=%t [GPIO DRIVER] : waiting for item [%0d]", $time, num_items_received);
        drv_box.get(item);
        write(item);
      end
    endtask;
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
    event           data_written;

    function new(virtual gpio_if vif, mailbox scb_box, event data_written);
      this.vif          = vif;
      this.scb_box      = scb_box;
      this.data_written = data_written;
    endfunction

    task run();
      transaction item;
      forever begin
        @(data_written);
        // ignore the 1st cycle
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
