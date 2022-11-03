class AHB_scoreboard;
  mailbox scb_expected_box;
  mailbox scb_observed_box;

  AHB_transaction expected_queue[$];

  int num_observed_items = 0;

  function new(mailbox scb_expected_box, mailbox scb_observed_box);
    this.scb_expected_box = scb_expected_box;
    this.scb_observed_box = scb_observed_box;
  endfunction

  task receive_expected_items();
    forever begin
      AHB_transaction item;
      scb_expected_box.get(item);
`ifdef DEBUG
      item.display("AHB SCOREBOARD");
`endif
      expected_queue.push_back(item);
    end
  endtask

  task receive_observed_items();
    forever begin
      AHB_transaction item, expected_item;
      scb_observed_box.get(item);
      expected_item = expected_queue.pop_front();
`ifdef DEBUG
      item.display("AHB SCOREBOARD");
      $display("==============================");
      $display("expected: %h observed: %h", expected_item.id, item.id);
`endif
      assert (expected_item.id === item.id);
      num_observed_items++;
    end
  endtask

  task run();
    fork
      receive_observed_items();
      receive_expected_items();
    join
  endtask

endclass : AHB_scoreboard
