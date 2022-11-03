package AHB_pkg;

  class transaction;
    static int        count        = 0;
    int               id;

    rand logic [15:0] data;
    rand logic        parity;
    rand logic        parity_sel;
    logic             real_parity;

    function void display(string tag = "");
      $display("T=%t [%s]", $time, tag);
      // $display("===== AHB transaction [%0d] =====", id);
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

  // Generator for AHB interface transaction
  class generator;
    rand transaction item;
    mailbox drv_box;  // send items to driver
    int repeat_cnt = 10;  // generate 10 transactions by default
    event finished;

    // constructor
    function new(mailbox box, int cnt, event finished);
      this.drv_box = box;  // getting driver mailbox form env
      this.repeat_cnt = cnt;
      this.finished = finished;
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
    endtask
  endclass : generator

  // Driver for AHB interface
  class driver;
    virtual ahb_if vif;
    mailbox drv_box;
    mailbox scb_expected_box;
    int num_transactions_received = 0;

    // constructor
    function new(virtual ahb_if vif, mailbox drv_box, mailbox scb_expected_box);
      this.vif              = vif;
      this.drv_box          = drv_box;
      this.scb_expected_box = scb_expected_box;
    endfunction

    //Reset task, Reset the Interface signals to default/initial values
    task reset;
      wait (!vif.reset_n);
      $display("T=%t [AHB DRIVER] : reset started", $time);
      vif.sel   <= 'b0;
      vif.addr  <= 'h0;
      vif.write <= 'b0;
      vif.size  <= 'h0;
      vif.trans <= 'h0;
      vif.wdata <= 'h0;
      wait (vif.reset_n);
      $display("T=%t [AHB DRIVER] : reset ended", $time);
    endtask

    task run();
      $display("T=%t [AHB DRIVER] : starting", $time);
      @(posedge vif.clk);
      $display("T=%t [AHB DRIVER] : starting", $time);

      forever begin
        transaction item;
        vif.sel   <= 1'b0;
        vif.write <= 1'b0;

        $display("T=%t [AHB DRIVER] : waiting for item [%0d]", $time, num_transactions_received);
        drv_box.get(item);
        scb_expected_box.put(item);
`ifdef DEBUG
        item.display("AHB DRIVER");
`endif
        vif.sel   <= 1'b1;
        vif.addr  <= item.addr;
        vif.write <= item.write;
        vif.size  <= item.size;
        vif.trans <= item.trans;
        vif.wdata <= item.wdata;

        @(posedge vif.clk);
        while (!vif.ready) begin
          $display("T=%t [AHB DRIVER] : waiting until ready is asserted", $time);
          @(posedge vif.clk);
        end

        vif.sel   <= 1'b0;
        vif.write <= 1'b0;
        num_transactions_received++;
      end
    endtask
  endclass : driver

  // Monitor for AHB interface
  class monitor;
    virtual ahb_if vif;
    mailbox scb_observed_box;

    function new(mailbox scb_observed_box);
      this.scb_observed_box = scb_observed_box;
    endfunction

    task run();
      $display("T=%t [AHB Monitor] : starting", $time);

      forever begin
        @(posedge vif.clk);
        if (vif.sel) begin
          transaction item = new();
          item.addr   = vif.addr;
          item.trans  = vif.trans;
          item.write  = vif.write;
          item.size   = vif.size;
          item.wdata  = vif.wdata;
          item.rdata  = vif.rdata;
          item.parity = vif.parity;

          // item.display("AHBMONITOR");

          scb_observed_box.put(item);
        end
      end
    endtask
  endclass : monitor


endpackage : AHB_pkg
