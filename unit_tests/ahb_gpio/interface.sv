interface ahb_if (
    input logic clk
);
  logic        HRESTn;
  logic        HSEL;
  logic        HREADY;
  logic [31:0] HADDR;
  logic [ 1:0] HTRANS;
  logic        HWRITE;
  logic [ 2:0] HSIZE;
  logic [31:0] HWDATA;
  logic        HREADYOUT;
  logic [31:0] HRDATA;
endinterface
