package ahb_pkg;

  logic [31:0] AHB_DATA_ADDR = 32'h5300_0000;
  logic [31:0] AHB_DIR_ADDR = 32'h5300_0004;

  // Transaction for AHB
  class transaction;
    rand logic [15:0] data;
    bit               parity;
    bit               parity_sel;

    function void display(string tag = "");
      $display("T=%t [%s] :", $time, tag);
      // $display("===== AHB transaction [%0d] =====", id);
      $display("data:   0x%4h", data);
      $display("parity: %1b", parity);
    endfunction : display

    // constructor
    function new();
    endfunction : new

    function void calc_parity();
      parity = parity_sel ? ~(^data) : ^data;
    endfunction

  endclass : transaction

  // Generator for AHB interface transaction
  class generator;
    rand transaction item;
    mailbox drv_box;  // send items to driver
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
    endtask
  endclass : generator

  // Driver for AHB interface
  class driver;
    virtual ahb_if vif;
    virtual err_if err_vif;
    mailbox        drv_box;
    // mailbox scb_expected_box;
    int num_items_received = 0;
    bit write = 1;

    // constructor
    function new(virtual ahb_if vif, virtual err_if err_vif, mailbox drv_box);
      this.vif     = vif;
      this.drv_box = drv_box;
      this.err_vif = err_vif;
      // this.scb_expected_box = scb_expected_box;
    endfunction

    //Reset task, Reset the Interface signals to default/initial values
    task reset;
      wait (!vif.reset_n);
      $display("T=%t [AHB DRIVER] : reset started", $time);
      num_items_received = 0;
      vif.sel   <= 'b0;
      vif.addr  <= 'h0;
      vif.write <= 'b0;
      vif.size  <= 'h0;
      vif.trans <= 'h0;
      vif.wdata <= 'h0;
      wait (vif.reset_n);
      $display("T=%t [AHB DRIVER] : reset ended", $time);
    endtask

    task switch_mode(bit write);
      @(posedge vif.clk);
      vif.sel   <= 1'b1;
      vif.addr  <= AHB_DIR_ADDR;
      vif.write <= 1'b1;
      vif.size  <= 3'b010;
      vif.trans <= 2'b10;
      vif.ready <= 1'b1;
      @(posedge vif.clk);  // r/w mode configuration taks 2 cycles
      vif.sel   <= 1'b0;
      vif.wdata <= write ? 16'h0001 : 16'h0000;
    endtask

    task run();
      @(posedge vif.clk);
      $display("T=%t [AHB DRIVER] : starting", $time);

      forever begin
        if (write) begin
          // $display("========================================");
          // $display("write");
          transaction item;
          vif.sel   <= 1'b0;
          vif.write <= 1'b0;

          $display("T=%t [AHB DRIVER] : waiting for item [%0d]", $time, num_items_received);
          drv_box.get(item);
`ifdef DEBUG
          item.display("AHB DRIVER");
`endif
          // TODO: no need to reprogram GPIO if last mode is write
          // set GPIO to write mode regardless the last mode
          switch_mode(1);

          @(posedge vif.clk);
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DATA_ADDR;
          vif.write <= 1'b1;
          vif.size  <= 3'b010;
          vif.trans <= 2'b10;
          vif.wdata <= item.data;
          vif.ready <= 1'b1;

          @(posedge vif.clk);
          while (!vif.readyout) begin
            $display("T=%t [AHB DRIVER] : waiting until readyout is asserted", $time);
            @(posedge vif.clk);
          end

          vif.sel   <= 1'b0;
          vif.write <= 1'b0;
        end else begin
          // $display("========================================");
          // $display("read");
          err_vif.error = $urandom_range(0, 1);
          switch_mode(0);
          // error <= 1;

          @(posedge vif.clk);
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DATA_ADDR;
          vif.write <= 1'b0;

          @(posedge vif.clk);
          // vif.sel   <= 1'b0;
          // vif.write <= 1'b0;

          // TODO:
          num_items_received++;
          err_vif.error = 0;
        end

        // Alternating reads and writes
        write++;
      end
    endtask
  endclass : driver

  // Monitor for AHB interface
  class monitor;
    virtual ahb_if vif;
    mailbox        scb_observed_box;
    mailbox        scb_expected_box;
    bit            parity_sel;

    function new(virtual ahb_if vif, mailbox scb_observed_box, mailbox scb_expected_box,
                 bit parity_sel);
      this.vif              = vif;
      this.scb_observed_box = scb_observed_box;
      this.scb_expected_box = scb_expected_box;
      this.parity_sel       = parity_sel;
    endfunction

    task run();
      $display("T=%t [AHB Monitor] : starting", $time);

      forever begin
        @(posedge vif.clk);
        if (vif.sel && (vif.addr === AHB_DATA_ADDR)) begin
          if (vif.write) begin
            transaction item = new();
            item.data       = vif.wdata[15:0];
            item.parity_sel = parity_sel;
            item.calc_parity();
`ifdef DEBUG
            item.display("AHBMONITOR WRITE ");
`endif
            scb_expected_box.put(item);
          end else begin
            transaction item = new();
            item.data       = vif.rdata[15:0];
            item.parity_sel = parity_sel;
            item.parity     = vif.rdata[16];
`ifdef DEBUG
            item.display("AHBMONITOR READ ");
`endif
            scb_observed_box.put(item);
          end
        end
      end
    endtask
  endclass : monitor


  // Scoreboard
  class scoreboard;
    mailbox scb_expected_box;
    mailbox scb_observed_box;
    virtual err_if err_vif;
    virtual gpio_if gpio_vif;

    transaction expected_queue[$];

    int num_items_observed = 0;

    function new(mailbox scb_expected_box, mailbox scb_observed_box, virtual err_if err_vif, virtual gpio_if gpio_vif);
      this.scb_expected_box = scb_expected_box;
      this.scb_observed_box = scb_observed_box;
      this.gpio_vif         = gpio_vif;
      this.err_vif          = err_vif;
    endfunction

    task receive_expected_items();
      forever begin
        transaction item;
        scb_expected_box.get(item);
`ifdef DEBUG
        item.display("SCOREBOARD");
`endif
        expected_queue.push_back(item);
      end
    endtask

    task receive_observed_items();
      forever begin
        transaction item, expected_item;
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
        assert (err_vif.error == gpio_vif.PARITY_ERR);
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

endpackage : ahb_pkg
