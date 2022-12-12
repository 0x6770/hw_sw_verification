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
      fd = $fopen ("Observed_Output_text", "w");
        for(int i =1; i <= 520; i ++) begin
            $fdisplay (fd, "%b", frame[i]);
          end
      $fclose(fd);
  endtask

  //   //OLD:: monitor one line for the vga outputs, each line is consisit of 640 pixels
  // here we wait for 4 cycles since the input clock frq is twice the VGA clk frequency
    task monitor_for_line(output [1:705] row ) ;
      wait(HSYNC==1);
      for(int i = 1; i <= 705; i++) begin
          if(RGB == 8'h00 )
            row[i] = 0;
          else if(RGB == 8'h1c )
            row[i] = 1;
          else
            row[i] = 1'dx;
          @CLK;
          @CLK;
          @CLK;
          @CLK;
      end
    endtask

  //   //OLD:: monitor one frame for the vga outputs, each frame is consisit of 480 lines
    task monitor_for_frame(output [1:705] frame [1:520]);
      wait(VSYNC==1);
      //$display("time: %b", $realtime);
      for (int j = 1; j <=520; j++) begin
          monitor_for_line(frame[j]);
          @(posedge HSYNC);
      end
    endtask

// Note: you can modify this to give a 50MHz clock or whatever is appropriate
  // monitor one line for the vga outputs, each line is consisit of 640 pixels
    // task monitor_for_line(output [7:0] row [1:705]) ;
    //   wait(HSYNC==1);
    //   for(int i = 1; i <= 705; i++) begin
    //       //covRGB.sample();   
    //       if(RGB == 8'h00 || RGB == 8'h1c)
    //         row[i] = RGB;
    //       else 
    //         row[i] = 8'h00;
    //       @CLK;
    //       @CLK;
    //   end
    // endtask

    // monitor one frame for the vga outputs, each frame is consisit of 480 lines
    // task monitor_for_frame(output [7:0] frame [1:520][1:705]);
    //   wait(VSYNC==1);
    //   //$display("time: %b", $realtime);
    //   for (int j = 1; j <=520; j++) begin
    //       monitor_for_line(frame[j]);
    //       @(posedge HSYNC);
    //   end
    // endtask

  //  task write_to_file(input[7:0] frame [1:520][1:705] );
  //       int fd;
  //       fd = $fopen ("Observed_Output", "w");
  //         for(int i =1; i <= 520; i ++) begin
  //           for(int j =1; j <= 705; j ++) begin
  //             $fwrite (fd, "%c", frame[i][j]);
  //           end
  //       end
  //       $fclose(fd);
  //   endtask

initial
begin
   CLK=0;
   forever
   begin
      #5 CLK=1;
      #5 CLK=0;
   end
end

initial
begin
   RESET=0;
   #30 RESET=1;
   #20 RESET=0;
end

  initial begin
    logic [1:705] frame [1:520];
    //logic [7:0] frame [1:520][1:705];            
    monitor_for_frame(frame);
    write_to_file(frame);
    $finish;
  end

endmodule

