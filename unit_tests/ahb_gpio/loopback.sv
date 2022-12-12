module loopback (
    input clk,
    input reset_n,
    input logic [16:0] GPIO_OUT,
    output logic [16:0] GPIO_IN
);
  logic [16:0] temp;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      temp <= 'h0;
    end else begin
      // $display("loopback GPIOOUT: %h", GPIO_OUT);
      temp <= GPIO_OUT;
    end
  end

  assign GPIO_IN = temp;

endmodule
