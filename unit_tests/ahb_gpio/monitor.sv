class AHB_monitor;
  virtual ahb_if vif;
  mailbox scb_observed_box;

  function new(mailbox scb_observed_box);
    this.scb_observed_box = scb_observed_box;
  endfunction

  task run();
    $display("T=%t [AHB Monitor] : starting", $time);

    //   forever begin
    //     @(posedge vif.clk);
    //     if (vif.sel) begin
    //       AHB_transaction item = new();
    //       item.addr  = vif.addr;
    //       item.wdata = vif.wdata;

    //       if (!vif.write) begin
    //         @(posedge vif.clk);
    //         item.rdata = vif.rdata;
    //       end

    //       item.display("AHB Monitor");
    //       scb_box.put(item);
    //     end
    //   end
  endtask
endclass : AHB_monitor
