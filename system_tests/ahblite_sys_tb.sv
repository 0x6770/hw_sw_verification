`timescale 1ns/1ps

module ahblite_sys_tb(

);

reg RESET, CLK;

wire [7:0] LED;
wire HSYNC;
wire VSYNC;
wire [7:0] RGB;

AHBLITE_SYS dut(.CLK(CLK), .RESET(RESET), .LED(LED), .HSYNC(HSYNC), .VSYNC(VSYNC), 
                .VGARED(RGB[7:5]), .VGAGREEN(RGB[4:2]), .VGABLUE(RGB[1:0]));

  task write_to_file(input[ 1:705] frame [1:520] );
      int fd;
      fd = $fopen ("Observed_frame.txt", "w");
        for(int i =1; i <= 520; i ++) begin
            $fdisplay (fd, "%b", frame[i]);
          end
      $fclose(fd);
  endtask

  //   //OLD:: monitor one frame for the vga outputs, each frame is 705x520 pixels
    task monitor_for_frame(output [1:705] frame [1:520]);
      $display("time: %t", $time);
      @(posedge VSYNC);
      $display("time: %t", $time);
      for (int j = 1; j <=520; j++) begin
          @(posedge HSYNC);
          for(int i = 1; i <= 705; i++) begin
              if(RGB == 8'h00 )
                frame[j][i] = 0;
              else if(RGB == 8'h1c )
                frame[j][i] = 1;
              else
                frame[j][i] = 1'dx;
              @(posedge CLK);
              @(posedge CLK);
              @(posedge CLK);
              @(posedge CLK);
          end
          @(posedge HSYNC);
      end
    endtask


  initial
  begin
    CLK=0;
    forever
    begin
      #10 CLK=1;
      #10 CLK=0;
    end
  end

  initial
  begin
    RESET=0;
    #30 RESET=1;
    #20 RESET=0;
  end

  initial begin
    @(posedge HSYNC);
    $display("time: %t", $time);
  end

  logic [1:705] frame [1:520];

  initial begin
    $display("start test");
    
    //logic [7:0] frame [1:520][1:705];            
    monitor_for_frame(frame);
    write_to_file(frame);
    $finish;
  end

endmodule

