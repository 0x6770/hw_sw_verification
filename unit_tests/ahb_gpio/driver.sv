class AHB_driver;
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
      AHB_transaction item;
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
endclass : AHB_driver
