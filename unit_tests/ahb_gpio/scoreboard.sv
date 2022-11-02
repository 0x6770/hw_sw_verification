class AHB_scoreboard;
  mailbox scb_expected_box;
  mailbox scb_observed_box;

  AHB_transaction expected_queue[$];

  function new(mailbox scb_expected_box, mailbox scb_observed_box);
    this.scb_expected_box = scb_expected_box;
    this.scb_observed_box = scb_observed_box;
  endfunction

  function append_to_expceted_queue(AHB_transaction item);
    expected_queue.push_back(item);
  endfunction

  function check_observed_item(AHB_transaction item_obs);
    AHB_transaction item_exp;
    item_exp = expected_queue.pop_front();
    assert (item_exp.id === item_obs.id);
  endfunction

  task run();
    forever begin
      AHB_transaction item;
      scb_expected_box.get(item);
      item.display("AHB SCOREBOARD");

      //     if (item.write) begin
      //       if (observed_queue[item.addr] == null) begin
      //         observed_queue[item.addr] = new();
      //       end

      //       observed_queue[item.addr] = item;
      //       $display("T=%t [AHB SCOREBOARD] addr=0x%0h write=0x%0h data=0x%0h", $time, item.addr,
      //                item.write, item.wdata);
      //     end else begin
      //       if (observed_queue[item.addr] == null) begin
      //         observed_queue[item.addr] = new();
      //       end
      // end

    end
  endtask

endclass : AHB_scoreboard
