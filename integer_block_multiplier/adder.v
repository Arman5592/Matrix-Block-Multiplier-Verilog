module adder
        #(parameter w=8);
        (
        input_a,
        input_b,
        input_stb,
        output_z_ack,
        clk,
        rst,
        output_z,
        output_z_stb);

  input     clk;
  input     rst;

  input     [w-1:0] input_a;
  input     input_stb;

  input     [w-1:0] input_b;

  output    [w-1:0] output_z;
  output    output_z_stb;
  input     output_z_ack;

  assign $signed(output_z) = $signed(input_a) + $signed(input_b);
 assign input_a_ack = 'b1;
 assign input_b_ack = 'b1;
 assign output_z_stb = 'b1;

endmodule
