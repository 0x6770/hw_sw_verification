interface ahb_if (
    input logic clk,
    input logic reset_n  // active low reset
);
  logic        sel;  // slave select signal
  logic        ready;  // previous transfer has finished on the bus [multiplexor to master/slave]
  logic [31:0] addr;  // address
  logic [ 1:0] trans;  // transfer type
  logic        write;  // transfer direction
  logic [ 2:0] size;  // transfer size
  logic [31:0] wdata;  // write data bus
  logic        readyout;  // slave transfer complete
  logic [31:0] rdata;  // read data bus

  modport driver(
      // global
      input clk,
      input reset_n,
      // select
      output sel,
      // address and control
      output addr,
      output write,
      output size,
      output trans,
      // data
      input rdata,
      output wdata,
      // transfer response
      input ready
  );
  modport dut(
      // global
      input clk,
      input reset_n,
      // select
      input sel,
      // address and control
      input addr,
      input write,
      input size,
      input trans,
      // data
      input wdata,
      output rdata,
      // transfer response
      input ready,
      output readyout
  );
endinterface
