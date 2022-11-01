class AHB_driver;
  virtual ahb_if vif;
  mailbox drv_box;

  task run();
    $display("T=0%t [AHB Driver] : starting", $time);
    @(posedge ahb_if.clk);

    forever begin
      AHB_transaction item;

      $display("T=0%t [AHB Driver] : waiting for item", $time);
      drv_box.get(item);
      item.display("AHB Driver");
      vif.sel  <= 1'b1;
      vif.addr <= item.addr;
      vif.data <= item.data;

      @(posedge ahb_if.clk);
      while (!vif.ready) begin
        $display("T=0%t [AHB Driver] : waiting until ready is asserted", $time);
        @(posedge ahb_if.clk);
      end

      vif.sel <= 0;
    end
  endtask
endclass : AHB_driver
