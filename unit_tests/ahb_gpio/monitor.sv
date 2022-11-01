class AHB_monitor;
  virtual ahb_if vif;
  mailbox scb_box;

  task run();
    $display("T=0%t [AHB Monitor] : starting");

    forever begin
      @(posedge vif.clk);
      if (vif.HSEL) begin
        AHB_transaction item = new();
        item.addr = vif.addr;
        item.data = vid.data;

        if (!vif.wr) begin
          @(posedge vid.clk);
          item.rdata = vif.rdata;
        end

        item.display("AHB Monitor");
        scb_box.put(item);
      end
    end
  endtask
endclass
