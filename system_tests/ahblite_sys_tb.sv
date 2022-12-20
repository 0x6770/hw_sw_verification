`timescale 1ns/1ps

module ahblite_sys_tb #(
  parameter int WIDTH  = 705,
  parameter int HEIGHT = 520
) ();

  bit RESET, CLK;

  wire  [16:0] LED;
  logic [16:0] SW;
  wire         PARITYSEL;
  wire         PARITYERR;

  wire HSYNC;
  wire VSYNC;
  wire [7:0] RGB;

  always #5 CLK = ~CLK;
  assign PARITYSEL=$urandom()%2;

  initial begin
    RESET=0;
    #50 RESET=1;
  end

  always @(posedge CLK or negedge RESET) begin
    if (!RESET) begin
      SW <= 17'h0ff;
    end else begin
      SW <= SW + 1;
    end
  end


  AHBLITE_SYS dut(
    // Clocking
    .CLK(CLK), .RESET(RESET), 
    // GPIO
    .LED(LED), .SW(SW), .PARITYSEL(PARITYSEL), .PARITYERR(PARITYERR),
    // VGA
    .HSYNC(HSYNC), .VSYNC(VSYNC),
    .VGARED(RGB[7:5]), .VGAGREEN(RGB[4:2]), .VGABLUE(RGB[1:0])
  );

  // monitor one frame for the vga outputs, each frame is 705x520 pixels
  task monitor_for_frame();
    automatic int cnt = 0;
    static int fd = $fopen("frame.ppm", "w");

    // PPM header
    $fdisplay(fd, "P2\n%d %d\n28\n", WIDTH, HEIGHT);

    @(posedge VSYNC);
    for (int j = 0; j < HEIGHT; j++) begin
        @(posedge HSYNC);
        $display("line %d: %t", cnt, $time);
        for(int i = 0; i < WIDTH; i++) begin
            $fdisplay(fd, "%d ", RGB);
            @(posedge CLK);
            @(posedge CLK);
            @(posedge CLK);
            @(posedge CLK);
        end
        cnt++;
    end
  endtask
 
  initial begin
    $display("start test");
    monitor_for_frame();
    $finish;
  end

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
