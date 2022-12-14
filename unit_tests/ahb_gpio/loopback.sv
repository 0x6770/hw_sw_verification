module loopback (
    input clk,
    input reset_n,
    input bit error_i,  // control whether flip parity bit at output
    input logic [16:0] GPIOOUT_i,
    output logic [16:0] GPIOIN_o
);
  logic [16:0] temp;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      temp <= 'h0;
    end else begin
      temp <= GPIOOUT_i;
    end
  end

  assign GPIOIN_o = {error_i ? ~temp[16] : temp[16], temp[15:0]};
endmodule
