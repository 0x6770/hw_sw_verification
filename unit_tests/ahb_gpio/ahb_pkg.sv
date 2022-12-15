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
    int n = 0;

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
        n++;
      end
      ->finished;
      $display("generated %d transactions", n);
    endtask
  endclass : generator

  // Driver for AHB interface
  class driver;
    virtual ahb_if vif;
    virtual err_if err_vif;
    mailbox        drv_box;
    // mailbox scb_expected_box;
    int            num_items_received = 0;
    bit            write              = 1;

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
      vif.wdata <=  'b0;
      @(posedge vif.clk);  // r/w mode configuration taks 2 cycles
      vif.sel   <= 1'b0;
      vif.addr  <=  'b0;
      vif.write <= 1'b0;
      vif.size  <= 3'b0;
      vif.trans <= 2'b0;
      vif.wdata <= write ? 16'h1 : 16'h0;
    endtask

    // write takes 2 cycles to complete
    task write_data(transaction item);
      @(posedge vif.clk);
      vif.sel   <= 1'b1;
      vif.addr  <= AHB_DATA_ADDR;
      vif.write <= 1'b1;
      vif.size  <= 3'b010;
      vif.trans <= 2'b10;
      vif.wdata <=  'b0;
      vif.ready <= 1'b1;
      @(posedge vif.clk); 
      vif.sel         <= 1'b0;
      vif.write       <= 1'b0;
      vif.wdata[15:0] <= item.data;
    endtask

    task read_data();
      @(posedge vif.clk);
      vif.sel       <= 1'b1;
      vif.write     <= 1'b0;
      // err_vif.error <= $urandom_range(0, 1);
      // err_vif.error <= 1;
    endtask

    task keep_write();
      $display("T=%t [AHB DRIVER] : starting", $time);

      forever begin
        transaction item;
        $display("T=%t [AHB DRIVER] : waiting for item [%0d]", $time, num_items_received);
        drv_box.get(item);
`ifdef DEBUG
        item.display("AHB DRIVER");
`endif
        write_data(item);
        // @(posedge vif.clk);
        num_items_received++;
      end
    endtask

    task keep_read();
      @(posedge vif.clk);
      $display("T=%t [AHB DRIVER] : starting", $time);

      forever begin
        read_data();
      end
    endtask
    
  endclass : driver

  // Monitor for AHB interface
  class wdata_monitor;
    virtual ahb_if vif;
    mailbox        scb_box;
    bit            parity_sel;
    event          data_written;

    function new(virtual ahb_if vif, mailbox scb_box, bit parity_sel, event data_written);
      this.vif          = vif;
      this.scb_box      = scb_box;
      this.parity_sel   = parity_sel;
      this.data_written = data_written;
    endfunction

    task run();
      transaction item;
      $display("T=%t [AHB WDATA Monitor] : starting", $time);
      forever begin
        @(posedge vif.clk);
        if (vif.sel && (vif.addr === AHB_DATA_ADDR) && vif.write) begin
          @(posedge vif.clk);
          item             = new();
          item.data        = vif.wdata[15:0];
          item.parity_sel  = parity_sel;
          item.calc_parity();
`ifdef DEBUG
          item.display("AHBMONITOR HWDATA");
`endif
          scb_box.put(item);
          ->data_written;
        end
      end
    endtask
  endclass : wdata_monitor

  class rdata_monitor;
    virtual ahb_if vif;
    mailbox        scb_box;
    bit            parity_sel;
    event          data_written;

    function new(virtual ahb_if vif, mailbox scb_box, bit parity_sel, event data_written);
      this.vif          = vif;
      this.scb_box      = scb_box;
      this.parity_sel   = parity_sel;
      this.data_written = data_written;
    endfunction

    task run();
        transaction item;
      $display("T=%t [AHB RDATA Monitor] : starting", $time);

      forever begin
        @(data_written);
        item             = new();
        item.data        = vif.rdata[15:0];
        item.parity      = vif.rdata[16];
        item.parity_sel  = this.parity_sel;
        item.calc_parity();
`ifdef DEBUG
        item.display("AHBMONITOR HRDATA");
`endif
        scb_box.put(item);
      end
    endtask
  endclass : rdata_monitor

endpackage : ahb_pkg
