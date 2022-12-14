//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (�LICENCE�) IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


module AHBGPIO #(
    parameter logic [15:0] GPIO_DATA_ADDR = 8'h00,
    parameter logic [15:0] GPIO_DIR_ADDR  = 8'h04
) (
    input wire HCLK,
    input wire HRESETn,
    input wire [31:0] HADDR,
    input wire [1:0] HTRANS,
    input wire [31:0] HWDATA,
    input wire HWRITE,
    input wire HSEL,
    input wire HREADY,
    input wire [16:0] GPIOIN,
    input wire PARITYSEL,  // 1'b1 ? odd parity : even parity

    //Output
    output wire HREADYOUT,
    output wire [31:0] HRDATA,
    output wire [16:0] GPIOOUT,
    output wire PARITYERR  // 1'b1 if parity error is detected
);
  function logic parity (logic[15:0] data, logic SEL);
		parity = SEL ? ~(^data) : ^data;
	endfunction

  reg [15:0] gpio_dataout;
  reg [16:0] gpio_datain;
  reg [15:0] gpio_dir;
  reg [16:0] gpio_data_next;
  reg [31:0] last_HADDR;
  reg [1:0] last_HTRANS;

  reg last_HWRITE;
  reg last_HSEL;

  assign HREADYOUT = 1'b1;

  // Set Registers from address phase
  always @(posedge HCLK) begin
    if (HREADY) begin
      last_HADDR  <= HADDR;
      last_HTRANS <= HTRANS;
      last_HWRITE <= HWRITE;
      last_HSEL   <= HSEL;
    end
  end

  // Update in/out switch
  always @(posedge HCLK, negedge HRESETn) begin
    // if (HRESETn) begin
    //   $display(last_HADDR[7:0]);
    // end
    if (!HRESETn) begin
      gpio_dir <= 16'h0000;
    end else if ((last_HADDR[7:0] == GPIO_DIR_ADDR) & last_HSEL & last_HWRITE & last_HTRANS[1]) begin
      // $display("configure mode =============================================");
      gpio_dir <= HWDATA[15:0];
    end
  end

  // Update output value
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      gpio_dataout <= 16'h0000;
    end
    else if ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == GPIO_DATA_ADDR) & last_HSEL & last_HWRITE & last_HTRANS[1]) begin
      gpio_dataout <= HWDATA[15:0];
    end
  end

  // Update input value
  always @(posedge HCLK, negedge HRESETn) begin
    // if (HRESETn) begin
    //   $display("gpio direction: %d, GPIOOUT: %h, GPIOIN: %h", gpio_dir, GPIOOUT, GPIOIN);
    // end
    if (!HRESETn) begin
      gpio_datain <= 17'h0000;
    end else if (gpio_dir == 16'h0000) gpio_datain <= GPIOIN;
    else if (gpio_dir == 16'h0001) gpio_datain <= GPIOOUT;
  end

  assign HRDATA[16:0] = gpio_datain;
  assign GPIOOUT = {parity(gpio_dataout, PARITYSEL), gpio_dataout};
  // Parity
  // assign PARITYERR = parity_err;
  assign PARITYERR = HRDATA[16] !== parity(HRDATA[15:0], PARITYSEL);


  //**************************************************************************//
  //******************************* ASSERTIONS *******************************//
  //**************************************************************************//

  // Auxiliary code
  `define ASSERT(EXP)\
    assert property (@(posedge HCLK) disable iff (!HRESETn) EXP)
  `define COVER(EXP)\
    cover property (@(posedge HCLK) disable iff (!HRESETn) EXP)

  logic READ;
  always_comb READ = (gpio_dir == 16'h0001) & (last_HADDR[7:0] == GPIO_DATA_ADDR) & last_HSEL & last_HWRITE & last_HTRANS[1];
  logic WRITE;
  always_comb WRITE = (gpio_dir == 16'h0001) & (last_HADDR[7:0] == GPIO_DATA_ADDR) & last_HSEL & last_HWRITE & last_HTRANS[1];
  logic TURN;
  always_comb TURN = (last_HADDR[7:0] == GPIO_DIR_ADDR) & last_HSEL & last_HWRITE & last_HTRANS[1];

  // Assume addresses for DIR and DATA are different
  asm_GPIO_DIR_ADDR_and_GPIO_DATA_ADDR_different:
    assume property (@(posedge HCLK) disable iff (!HRESETn) GPIO_DIR_ADDR !== GPIO_DATA_ADDR);

  // Assertions for PARITYERR
  ast_PARITYERR_is_only_affected_by_PARITYSEL_GPIOIN_GPIOOUT_HRDATA:
    `ASSERT(($stable(GPIOIN) && $stable(GPIOOUT) && !TURN)[*2] |=> $stable(PARITYSEL) |-> $stable(PARITYERR));
  ast_PARITYERR_always_eq_parity_bit:
    `ASSERT(PARITYERR === (HRDATA[16] !== parity(HRDATA[15:0], PARITYSEL)));

  // Assertions for GPIOOUT
  ast_GPIOOUT_parity_generation:
    `ASSERT(GPIOOUT[16] === (PARITYSEL ? ~^GPIOOUT[15:0] : ^GPIOOUT[15:0]));
  ast_parity_bit_never_x_or_z:
    `ASSERT((GPIOOUT[16] === 1'b1) || (GPIOOUT[16] === 1'b0));

  // Assertions for HRDATA
  ast_HRDATA_data_part_eq_past_GPIOIN_if_gpio_dir_0:    
    `ASSERT(gpio_dir === 16'h0 |=> HRDATA[16:0] === $past(GPIOIN[16:0]));
  ast_HRDATA_data_part_eq_past_GPIOOUT_if_gpio_dir_1:    
    `ASSERT(gpio_dir === 16'h1 |=> HRDATA[16:0] === $past(GPIOOUT[16:0]));
  ast_HRDATA_data_part_only_changes_if_gpio_dir_0_or_1:    
    `ASSERT((gpio_dir !== 16'b1) && (gpio_dir !== 16'b0) |=> $stable(HRDATA[16:0]));
  
  ast_gpio_data_out_eq_past_HWDATA_when_WRITE:
    `ASSERT(WRITE |=> gpio_dataout === $past(HWDATA[15:0]));

  ast_gpio_dir_eq_past_HWDATA_when_TURN:
    `ASSERT(TURN |=> gpio_dir === $past(HWDATA[15:0]));

  ast_last_HADDR_eq_past_HADDR:
  `ASSERT(HREADY |=> last_HADDR  == $past(HADDR));
  ast_last_HTRANS_eq_past_HTRANS:
  `ASSERT(HREADY |=> last_HTRANS == $past(HTRANS));
  ast_last_HWRITE_eq_past_HWRITE:
  `ASSERT(HREADY |=> last_HWRITE == $past(HWRITE));
  ast_last_HSEL_eq_past_HSEL:
  `ASSERT(HREADY |=> last_HSEL   == $past(HSEL));

  cov_PARITYERR_hi: `COVER(PARITYERR === 1'b1);
  cov_PARITYERR_lo: `COVER(PARITYERR === 1'b0);
  
  cov_PARITYSEL_hi: `COVER(PARITYSEL === 1'b1);
  cov_PARITYSEL_lo: `COVER(PARITYSEL === 1'b0);
  
  cov_PARITYBIT_hi: `COVER(GPIOOUT[16] === 1'b1);
  cov_PARITYBIT_lo: `COVER(GPIOOUT[16] === 1'b0);
  
  cov_gpio_dir_hi: `COVER(gpio_dir === 16'b1);
  cov_gpio_dir_lo: `COVER(gpio_dir === 16'b0);

  cov_HSEL_hi: `COVER(HSEL === 1'b1);
  cov_HSEL_lo: `COVER(HSEL === 1'b0);

  cov_HWRITE_hi: `COVER(HWRITE === 1'b1);
  cov_HWRITE_lo: `COVER(HWRITE === 1'b0);
endmodule
