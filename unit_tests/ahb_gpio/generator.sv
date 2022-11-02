class AHB_generator;
  rand AHB_transaction item;
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
endclass
