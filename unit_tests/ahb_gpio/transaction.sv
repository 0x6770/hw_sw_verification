class AHB_transaction;
  static int        count   = 0;
  int               id;

  // AHB interface signals
  // logic             ready;
  rand logic [31:0] addr;
  rand logic [ 1:0] trans;
  rand logic        write;
  rand logic [ 2:0] size;
  rand logic [31:0] wdata;
  // logic             readyout;
  rand logic [31:0] rdata;
  rand logic        parity;

  function void display(string tag = "");
    $display("T=%t [%s]", $time, tag);
    // $display("===== AHB transaction [%0d] =====", id);
    $display("id:        %h", id);
    $display("HADDR:     %h", addr);
    $display("HWRITE:    %d", write);
    $display("HWDATA:    %h", wdata);
    $display("HRDATA:    %h", rdata);
    // $display("HREADY:    %h", ready);
    // $display("HREADYOUT: %h", readyout);
    $display("HTRANS:    %h", trans);
    $display("HSIZE:     %h", size);
    $display("parity:    %h", parity);
  endfunction : display

  function new();
    id = count++;
  endfunction : new

  function void check_parity();
    logic observed = ^wdata;
    if (observed === parity) begin
      $display("T=%t [AHB transaction] : parity match", $time);
    end else begin
      $display("T=%t [AHB transaction] : parity mismatch, observed: %0h expected: %0h", $time,
               observed, parity);
    end
  endfunction : check_parity

endclass : AHB_transaction
