module base_matrix_multiplier(
        i_a11,i_a12,i_a21,i_a22,
        i_b11,i_b12,i_b21,i_b22,
        start,
        clk,
        o_c11,o_c12,o_c21,o_c22,
        done);
input[31:0] i_a11,i_a12,i_a21,i_a22,i_b11,i_b12,i_b21,i_b22;
input clk;
input start;
output [31:0]  o_c11,o_c12,o_c21,o_c22;
output reg done = 0;


parameter s_idle =2'b00;
parameter s_setup =2'b01;
parameter s_mult =2'b10;
parameter s_add = 2'b11;
reg [1:0] state=s_idle;

wire [31:0] mult_a11_b11,mult_a11_b12,mult_a21_b11,mult_a21_b12,
            mult_a12_b21,mult_a12_b22,mult_a22_b21,mult_a22_b22;
wire a_ack,b_ack,z_stb;
reg a_stb,b_stb,z_ack,rst=1;

reg add_ack=0;
wire add_ready;

reg [31:0] r_a11,r_a12,r_a21,r_a22,r_b11,r_b12,r_b21,r_b22;

always @(posedge clk) begin
    case (state)
        s_idle: begin
            done <= 0;
            rst <= 1;
            add_ack <= 0;
            if (start) begin
                state <= s_setup;
                r_a11 <= i_a11;
                r_a12 <= i_a12;
                r_a21 <= i_a21;
                r_a22 <= i_a22;
                r_b11 <= i_b11;
                r_b12 <= i_b12;
                r_b21 <= i_b21;
                r_b22 <= i_b22;
            end
        end
        s_setup: begin
                a_stb <= 1;
                b_stb <= 1;
                z_ack <= 1;
                rst <= 0;
                state <= s_mult;
        end
        s_mult: begin
            z_ack = 0;
            if(z_stb == 1) begin
                state <= s_add;
                add_ack <= 1;
                a_stb <= 0;
                b_stb <= 0;
                z_ack <= 0;
            end
        end
        s_add: begin
            add_ack <= 0;
            if (add_ready) begin
                state <= s_idle;
                done <= 1;
            end
        end
    endcase     
end


single_multiplier multiplier_a11_b11(
    .clk(clk),
    .rst(rst),
    .input_a(r_a11),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b11),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a11_b11),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a11_b12(
    .clk(clk),
    .rst(rst),
    .input_a(r_a11),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b12),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a11_b12),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a21_b11(
    .clk(clk),
    .rst(rst),
    .input_a(r_a21),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b11),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a21_b11),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a21_b12(
    .clk(clk),
    .rst(rst),
    .input_a(r_a21),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b12),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a21_b12),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a12_b21(
    .clk(clk),
    .rst(rst),
    .input_a(r_a12),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b21),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a12_b21),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a12_b22(
    .clk(clk),
    .rst(rst),
    .input_a(r_a12),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b22),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a12_b22),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a22_b21(
    .clk(clk),
    .rst(rst),
    .input_a(r_a22),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b21),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a22_b21),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

single_multiplier multiplier_a22_b22(
    .clk(clk),
    .rst(rst),
    .input_a(r_a22),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(r_b22),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(mult_a22_b22),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

adder adder_c11(
    .clk(clk),
    .reset(state==s_add || state==s_idle),
    .load(1'b1),
    .Number1(mult_a11_b11),
    .Number2(mult_a12_b21),
    .result_ack(add_ack),
    .Result(o_c11),
    .result_ready(add_ready)
);

adder adder_c12(
    .clk(clk),
    .reset(state==s_add || state==s_idle),
    .load(1'b1),
    .Number1(mult_a11_b12),
    .Number2(mult_a12_b22),
    .result_ack(add_ack),
    .Result(o_c12),
    .result_ready(add_ready)
);

adder adder_c21(
    .clk(clk),
    .reset(state==s_add || state==s_idle),
    .load(1'b1),
    .Number1(mult_a21_b11),
    .Number2(mult_a22_b21),
    .result_ack(add_ack),
    .Result(o_c21),
    .result_ready(add_ready)
);
adder addder_c22(
    .clk(clk),
    .reset(state==s_add || state==s_idle),
    .load(1'b1),
    .Number1(mult_a21_b12),
    .Number2(mult_a22_b22),
    .result_ack(add_ack),
    .Result(o_c22),
    .result_ready(add_ready)
);

endmodule