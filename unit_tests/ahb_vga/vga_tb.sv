// vga testbench
program automatic vga_tb 
(vga_if.TEST vga_if); 

 logic [7:0] TEXT;   
 parameter H_LOW = 99;
 parameter V_LOW =30;

  class TEXT_RAND;                   // Declare a class to randomise the operand values
    rand logic [7:0]	TEXT;
    constraint ascii { TEXT inside {[32:127]};}
  endclass
  TEXT_RAND text_rand;

  covergroup cover_RGB;          
      coverpoint  vga_if.cb.RGB {
        bins zero = {8'h00};
        bins one = {8'h1c};
      }
  endgroup
  cover_RGB covRGB;

  covergroup cover_TEXT;          
      coverpoint  TEXT {
        bins special_char = {[32:47],[58:64],[91:96],[123:127]};
        bins number = {[48:57]};
        bins char = {[65:90],[97:122]};
      }  
  endgroup
  cover_TEXT covTEXT;

// create reference LUT for ASCII charater 1
  logic [1:8] text_reference_one [1:16];
  assign text_reference_one[1]  = 8'b00000000;
  assign text_reference_one[2]  = 8'b00000000;
  assign text_reference_one[3]  = 8'b00011000;
  assign text_reference_one[4]  = 8'b00111000;
  assign text_reference_one[5]  = 8'b01111000;
  assign text_reference_one[6]  = 8'b00011000;
  assign text_reference_one[7]  = 8'b00011000;
  assign text_reference_one[8]  = 8'b00011000;
  assign text_reference_one[9]  = 8'b00011000;
  assign text_reference_one[10] = 8'b00011000;
  assign text_reference_one[11] = 8'b00011000;
  assign text_reference_one[12] = 8'b01111110;
  assign text_reference_one[13] = 8'b00000000;
  assign text_reference_one[14] = 8'b00000000;
  assign text_reference_one[15] = 8'b00000000;
  assign text_reference_one[16] = 8'b00000000;


  //Reset
  task deassert_reset();
    begin
          // reset
          vga_if.HRESETn = 0; 
          // Set all signals to be the same status as Simulation shows
          vga_if.cb.HADDR  <= 32'h0000_0004;
          vga_if.cb.HSEL_VGA   <= 1'b0;
          vga_if.cb.HWRITE <= 1'b0;
          vga_if.cb.HTRANS <= 2'b0;
          vga_if.cb.HREADY <= 1'b1;
          vga_if.cb.HWDATA <= 32'h0000_0000;
          // keep reset low for 4 cycles
          @vga_if.cb;          
          @vga_if.cb;
          @vga_if.cb;
          @vga_if.cb;
          // Disable the reset signal
          vga_if.HRESETn = 1; 
    end
    endtask

  // AHB_BFM to write text into the VGA
  task vga_write(input [7:0] TEXT);
      covTEXT = new();
      begin
          @vga_if.cb 
          vga_if.cb.HREADY <= 1'b1;
          vga_if.cb.HADDR  <= 32'h5000_0000;
          vga_if.cb.HSEL_VGA  <= 1'b1;
          vga_if.cb.HWRITE <= 1'b1;
          vga_if.cb.HTRANS <= 2'b10;
          vga_if.cb.HWDATA <= {8'd0, TEXT, 16'd0};
          // Signals are high for one cycle then low
          @vga_if.cb 
          vga_if.cb.HADDR  <= 32'h0000_0094;
          vga_if.cb.HSEL_VGA   <= 1'b0;
          vga_if.cb.HWRITE <= 1'b0;
          vga_if.cb.HTRANS <= 2'b00;
          vga_if.cb.HWDATA <= {24'd0, TEXT};
          covTEXT.sample(); 
          // One more cycle to wait for gpio_dir signal to change
          @vga_if.cb 
          vga_if.cb.HTRANS <= 2'b10;
          vga_if.cb.HWDATA <= {8'd0, TEXT, 16'd0};
          // Assign R2 to be equal to HRDATA 
          @vga_if.cb
          vga_if.cb.HTRANS <= 2'b10;
          @vga_if.cb
          vga_if.cb.HTRANS <= 2'b00;
      end 

  endtask

    // initially write the "1TEST" to check the VGA works normally
    task initial_correct_check();                       // Initial check of correct GPIO input with an immediate output
	    begin
        wait (vga_if.HRESETn == 1'b1);		            // Wait for reset to be disabled
        #220
        TEXT = 8'h31;   //1
        vga_write(TEXT);        
        TEXT = 8'h54;   //T
        vga_write(TEXT);
        TEXT = 8'h45;   //E
        vga_write(TEXT);
        TEXT = 8'h53;   //S
        vga_write(TEXT);
        TEXT = 8'h54;   //T
        vga_write(TEXT);
        TEXT = 8'h0d;   // \n
        vga_write(TEXT);
      end
      //   assert (vga_if.DLS_ERROR == 1'b0)
      //   else $fatal ("Initial check of correct VGA failed");
	    // $display ("Initial check of correct VGA passed");
	  endtask

// automatic checker for the text input 1, verify the charater "1" display at the correct position of the monitor
    task auto_check(input [1:705] frame [1:520], input [1:8] reference [1:16]);
      bit match = 1;
      for (int i = 30; i <=45; i++) begin
          match = match & (frame[i][51:58] == reference[i-29]);
      end
      if (match == 1)
        $display ("Checking of charater 1 passed");
      else 
        $display ("Checking of charater 1 failed");
    endtask


  // randomly write 600 valid ASCII charaters to test the VGA display
    task constrained_random_check();
      int fd;
      fd = $fopen ("Expected_Output", "w");
      text_rand = new();
        wait (vga_if.HRESETn == 1'b1);		            // Wait for reset to be disabled
        #220
        for (int i = 0; i < 600; i++) begin
            text_rand.randomize();
            // $display ("Expected_text=%s", text_rand.TEXT);
            $fwrite (fd, "%c", text_rand.TEXT);
            TEXT = text_rand.TEXT;      //put randomised text into TEXT to be monitored for coverage
            vga_write(TEXT);
        end
        TEXT = 8'h0d;   // \n
        vga_write(TEXT); //write carrige return
      $fclose(fd);
    endtask

    // monitor one frame for the vga RGB outputs, the outputs are in bmp format
    task monitor_for_frame_bmp(output [7:0] frame [1:520][1:705]);
      wait(vga_if.cb.VSYNC==1);
      //$display("time: %b", $realtime);
      for (int j = 1; j <=520; j++) begin
        covRGB = new();
        wait(vga_if.cb.HSYNC==1);
        for(int i = 1; i <= 705; i++) begin
            //covRGB.sample();   
            if(vga_if.cb.RGB == 8'h00 || vga_if.cb.RGB == 8'h1c)
              frame[j][i] = vga_if.cb.RGB;
            else 
              frame[j][i] = 8'h00;
            @vga_if.cb;
            @vga_if.cb;
        end
        @(posedge vga_if.cb.HSYNC);
      end
    endtask

    //OLD:: monitor one frame for the vga outputs, each frame is consisit of 480 lines
    task monitor_for_frame_text(output [1:705] frame [1:520]);
      wait(vga_if.cb.VSYNC==1);
      for (int j = 1; j <=520; j++) begin
          //covRGB = new();
          wait(vga_if.cb.HSYNC==1);
          for(int i = 1; i <= 705; i++) begin
              //covRGB.sample();   
              if(vga_if.cb.RGB == 8'h00 )
                frame[j][i] = 0;
              else if(vga_if.cb.RGB == 8'h1c )
                frame[j][i] = 1;
              else
                frame[j][i] = 1'dx;
              @vga_if.cb;
              @vga_if.cb;
          end          
        @(posedge vga_if.cb.HSYNC);
      end
    endtask

    // // write the observed outputs to a bmp file
    task write_to_bmp(input[7:0] frame [1:520][1:705] );
        int fd;
        fd = $fopen ("Observed_Output_bmp", "w");
          for(int i =1; i <= 520; i ++) begin
            for(int j =1; j <= 705; j ++) begin
              $fwrite (fd, "%c", frame[i][j]);
            end
        end
        $fclose(fd);
    endtask

    // OLD: write the observed outputs to a text file
    task write_to_text(input[ 1:705] frame [1:520] );
        int fd;
        fd = $fopen ("Observed_Output_text", "w");
          for(int i =1; i <= 520; i ++) begin
              $fdisplay (fd, "%b", frame[i]);
            end
        $fclose(fd);
    endtask


  initial begin
    //create containter for holding frame in bmp format
    logic [7:0] frame_in_bmp [1:520][1:705];
    //create container for holding frame in text format
    logic [1:705] frame_in_text [1:520];

    // Direct test, checking charater "1" is displayed at the corrct position on the frame
    // An automatic checker is developed to perform comparison
    deassert_reset();                
    initial_correct_check();
    monitor_for_frame_text(frame_in_text);
    write_to_text(frame_in_text);
    auto_check(frame_in_text,text_reference_one);

    // Constrained random test, 600 random characters is given as input, and the output 
    // is cpnverted to a bit-map image for convinient observation
    deassert_reset();                
    constrained_random_check ();
    monitor_for_frame_bmp(frame_in_bmp);
    write_to_bmp(frame_in_bmp);
    $finish;

  end

    assert_AHB_behaviour1: assert property(     
                          @(posedge vga_if.cb) disable iff (!vga_if.HRESETn)
                            vga_if.cb.HSEL_VGA |-> (vga_if.cb.HWRITE) ##1 (!vga_if.cb.HWRITE)
                        );
    assert_AHB_behaviour2: assert property(     
                          @(posedge vga_if.cb) disable iff (!vga_if.HRESETn)
                            vga_if.cb.HWRITE  |-> (vga_if.cb.HSEL_VGA) ##1 (!vga_if.cb.HSEL_VGA)
                        );

    assert_AHB_behaviour3: assert property(     
                          @(posedge vga_if.cb) disable iff (!vga_if.HRESETn)
                            vga_if.cb.HWRITE |-> (vga_if.cb.HADDR  == 32'h5000_0000) ##1 (vga_if.cb.HADDR  != 32'h5000_0000)
                        );

    assert_AHB_behaviour4: assert property(     
                          @(posedge vga_if.cb) disable iff (!vga_if.HRESETn)
                            vga_if.cb.HWRITE |-> (vga_if.cb.HTRANS == 2'b10) ##1  (vga_if.cb.HTRANS != 2'b10)
                        );

    assert_AHB_behaviour5: assert property(     
                          @(posedge vga_if.cb) disable iff (!vga_if.HRESETn)
                            vga_if.cb.HWRITE |-> (vga_if.cb.HWDATA != {24'd0, TEXT}) ##1  (vga_if.cb.HWDATA == {24'd0, TEXT})
                        );

endprogram  