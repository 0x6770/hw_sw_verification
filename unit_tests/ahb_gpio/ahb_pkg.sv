package ahb_pkg;

  logic [31:0] AHB_DATA_ADDR = 32'h5300_0000;
  logic [31:0] AHB_DIR_ADDR = 32'h5300_0004;

  // Transaction for AHB
  class transaction;
    static int        count   = 0;
    int               id;

    rand logic [15:0] data;
    rand logic        parity;
    // rand logic        parity_sel;
    // logic             real_parity;

    function void display(string tag = "");
      $display("T=%t [%s] :", $time, tag);
      // $display("===== AHB transaction [%0d] =====", id);
      $display("id:     %-d", id);
      $display("data:   0x%4h", data);
      $display("parity: %1b", parity);
      // $display("parity_sel:  %h", parity_sel);
      // $display("real_parity: %h", real_parity);
    endfunction : display

    // constructor
    function new();
      id = count++;
      // real_parity = parity_sel ? ~(^data) : ^data;
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
    // mailbox scb_expected_box;
    int num_items_received = 0;
    bit write = 0;

    // constructor
    function new(virtual ahb_if vif, mailbox drv_box);
      this.vif     = vif;
      this.drv_box = drv_box;
      // this.scb_expected_box = scb_expected_box;
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
        // write_next = $urandom_range(0, 20) > 10;
        // $display("write: %h, write_next: %h", write, write_next);

        if (write) begin
          // $display("write");
          transaction item;
          vif.sel   <= 1'b0;
          vif.write <= 1'b0;

          $display("T=%t [AHB DRIVER] : waiting for item [%0d]", $time, num_items_received);
          drv_box.get(item);
          // scb_expected_box.put(item);
`ifdef DEBUG
          item.display("AHB DRIVER");
`endif

          // TODO: no need to reprogram GPIO if last mode is write
          // set GPIO to write mode regardless the last mode
          @(posedge vif.clk);
          // $display("========================================");
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DIR_ADDR;
          vif.write <= 1'b1;
          vif.size  <= 3'b010;
          vif.trans <= 2'b10;
          vif.wdata <= 16'h0001;  // AS OUTPUT

          @(posedge vif.clk);
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DATA_ADDR;
          vif.write <= 1'b1;
          vif.size  <= 3'b010;
          vif.trans <= 2'b10;
          vif.wdata <= item.data;

          @(posedge vif.clk);
          while (!vif.readyout) begin
            $display("T=%t [AHB DRIVER] : waiting until readyout is asserted", $time);
            @(posedge vif.clk);
          end

          vif.sel   <= 1'b0;
          vif.write <= 1'b0;
        end else begin
          // $display("read");
          // $display("========================================");
          @(posedge vif.clk);
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DIR_ADDR;
          vif.write <= 1'b1;
          vif.size  <= 3'b010;
          vif.trans <= 2'b10;
          vif.wdata <= 16'h0000;  // AS INPUT

          @(posedge vif.clk);
          vif.sel   <= 1'b1;
          vif.addr  <= AHB_DATA_ADDR;
          vif.write <= 1'b0;
          vif.size  <= 3'b010;
          vif.trans <= 2'b10;

          @(posedge vif.clk);
          // $display("vif.sel: %h\nvif.write: %h\nvif.addr: %h", vif.sel, vif.write, vif.addr);
          num_items_received++;
        end
        write += 1;
      end
    endtask
  endclass : driver

  // Monitor for AHB interface
  class monitor;
    virtual ahb_if vif;
    mailbox scb_observed_box;

    function new(virtual ahb_if vif, mailbox scb_observed_box);
      this.vif = vif;
      this.scb_observed_box = scb_observed_box;
    endfunction

    task run();
      $display("T=%t [AHB Monitor] : starting", $time);

      forever begin
        @(posedge vif.clk);
        if (vif.sel && (vif.addr === AHB_DATA_ADDR)) begin
          if (vif.write === 1'b1) begin
            transaction item = new();
            item.data = vif.wdata[15:0];
            item.display("AHBMONITOR WRITE");
          end else begin
            transaction item = new();
            item.data   = vif.rdata[15:0];
            item.parity = vif.rdata[16];
            item.display("AHBMONITOR READ");
            // scb_observed_box.put(item);
          end
        end
      end
    endtask
  endclass : monitor

endpackage : ahb_pkg
