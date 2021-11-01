module base_matrix_multiplier
        #(parameter w=8);
        (
        i_a11,i_a12,i_a21,i_a22,
        i_b11,i_b12,i_b21,i_b22,
        start,
        clk,
        o_c11,o_c12,o_c21,o_c22,
        done);
input[w-1:0] i_a11,i_a12,i_a21,i_a22,i_b11,i_b12,i_b21,i_b22;
input clk;
input start;
output [w-1:0]  o_c11,o_c12,o_c21,o_c22;
output reg done = 0;


parameter s_idle =2'b00;
parameter s_setup =2'b01;
parameter s_mult =2'b10;
parameter s_add = 2'b11;
reg [1:0] state=s_idle;

wire [w-1:0] mult_a11_b11,mult_a11_b12,mult_a21_b11,mult_a21_b12,
            mult_a12_b21,mult_a12_b22,mult_a22_b21,mult_a22_b22;
wire a_ack,b_ack,z_stb;
wire z_stb1,z_stb2,z_stb3,z_stb4,z_stb5,z_stb6,z_stb7,z_stb8;
reg a_stb,b_stb,z_ack,rst=1;

reg stb_adder,z_ack_adder;

reg add_reset=1;

wire [3:0] add_readies;
assign add_ready = &add_readies;
assign z_stb = z_stb1 & z_stb2 & z_stb3 & z_stb4 & z_stb5 & z_stb6 & z_stb7 & z_stb8;

reg [w-1:0] r_a11,r_a12,r_a21,r_a22,r_b11,r_b12,r_b21,r_b22;

always @(posedge clk) begin
    case (state)
        s_idle: begin
            done <= 0;
            rst <= 1;
            add_reset <= 1;
            z_ack_adder <= 0;
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
                add_reset <= 1;
        end
        s_mult: begin
            z_ack <= 0;
            if(z_stb == 1) begin
                state <= s_add;
                a_stb <= 0;
                b_stb <= 0;
                z_ack <= 0;

                stb_adder <= 1;
                z_ack_adder <=1;
                add_reset <= 0;
            end
        end
        s_add: begin
            z_ack_adder <= 0;
            if (add_ready) begin
            state <= s_idle;
            done <= 1;
            stb_adder <= 0;
            z_ack_adder <= 0;
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
    .output_z_stb(z_stb1),
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
    .output_z_stb(z_stb2),
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
    .output_z_stb(z_stb3),
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
    .output_z_stb(z_stb4),
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
    .output_z_stb(z_stb5),
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
    .output_z_stb(z_stb6),
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
    .output_z_stb(z_stb7),
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
    .output_z_stb(z_stb8),
    .output_z_ack(z_ack));

adder adder_c11(
    .clk(clk),
    .rst(add_reset),
    .input_a(mult_a11_b11),
    .input_b(mult_a12_b21),
    .output_z(o_c11),
    .output_z_stb(add_readies[0]),
    .input_stb(stb_adder),
    .output_z_ack(z_ack_adder)
);

adder adder_c12(
    .clk(clk),
    .rst(add_reset),
    .input_a(mult_a11_b12),
    .input_b(mult_a12_b22),
    .output_z(o_c12),
    .output_z_stb(add_readies[1]),
    .input_stb(stb_adder),
    .output_z_ack(z_ack_adder)
);

adder adder_c21(
    .clk(clk),
    .rst(add_reset),
    .input_a(mult_a21_b11),
    .input_b(mult_a22_b21),
    .output_z(o_c21),
    .output_z_stb(add_readies[2]),
    .input_stb(stb_adder),
    .output_z_ack(z_ack_adder)
);
adder addder_c22(
    .clk(clk),
    .rst(add_reset),
    .input_a(mult_a21_b12),
    .input_b(mult_a22_b22),
    .output_z(o_c22),
    .output_z_stb(add_readies[3]),
    .input_stb(stb_adder),
    .output_z_ack(z_ack_adder)
);

endmodule

//module test();
//
//reg [31:0] a11,a12,a21,a22,b11,b12,b21,b22;
//reg clk=0;
//reg start;
//wire [31:0]  c11,c12,c21,c22;
//wire done;
//base_matrix_multiplier mult(
//.i_a11(a11),
//.i_a12(a12),
//.i_a21(a21),
//.i_a22(a22),
//.i_b11(b11),
//.i_b12(b12),
//.i_b21(b21),
//.i_b22(b22),
//.clk(clk),
//.start(start),
//.o_c11(c11),
//.o_c12(c12),
//.o_c21(c21),
//.o_c22(c22),
//.done(done)
//);
// always #10 clk=~clk;  // 25MHz
//initial 
//$monitor ("%0t %h c11=%h c12=%h c21=%h c22=%h state: %d z_stb: %b add_ready: %b done: %b",$time,mult.mult_a11_b11,c11,c12,c21,c22,mult.state,mult.z_stb,mult.add_ready,mult.done);
//
//initial begin
//   #10
//   start = 1;
//   a11 = 32'h41f0f5c3;  //30.12
//   a12 = 32'h42ee999a;  //119.3
//   a21 = 32'h3ee66666;  //0.45
//   a22 = 32'h4158a3d7;  //13.54
//   b11 = 32'h42b6ae14;  //91.34
//   b12 = 32'h40400000;  //3
//   b21 = 32'h41000000;  //8
//   b22 = 32'h41780000;  //15.5
//   // c11=3705.5608    0x456798f8 
//   // c12=1939.51      0x44f27050
//   // c21=149.423      0x43156c49
//   // c22=211.22       0x43533850
//   #10
//   a11 = 32'h41f882f;  //30.12
//   a12 = 32'h42ee999a;  //119.3
//   a21 = 32'h3ee66666;  //0.45
//   a22 = 32'h4158a3d7;  //13.54
//   b11 = 32'h42b6a014;  //91.34
//   b12 = 32'h40400100;  //3
//   b21 = 32'h41010000;  //8
//   b22 = 32'h41780001;  //15.5
//   #5000
//   $finish;
//end
//endmodule
