class AHB_scoreboard;
  mailbox scb_box;
  AHB_transaction refq[256];

  task run();
    forever begin
      AHB_transaction item;
      scb_box.get(item);
      item.display("AHB scoreboard");

      if (item.wr) begin
        if (refq[item.addr] == null) begin
          refq[item.addr] = new();
        end

        refq[item.addr] = item;
        $display("T=0%t [AHB scoreboard] Store addr=0x%0h wr=0x%0h data=0x%0h", $time, item.addr,
                 item.wr, item.data);
      end else begin
        if (refq[item.addr] == null) begin
          refq[item.addr] = new();
        end
      end

    end
  endtask
endclass
