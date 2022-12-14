module loopback (
    input clk,
    input reset_n,
    input bit error, // control whether flip parity bit at output
    input logic [16:0] GPIOOUT,
    output logic [16:0] GPIOIN
);
  logic [16:0] temp;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      temp <= 'h0;
    end else begin
      // $display("loopback GPIOOUT: %h", GPIO_OUT);
      temp <= GPIOOUT;
    end
  end

  assign GPIOIN = {error ? ~temp[16] : temp[16], temp[15:0]};

endmodule
