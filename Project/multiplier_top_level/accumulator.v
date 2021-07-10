module accumulator(
        i_a11,i_a12,i_a21,i_a22,
        start,
        reset,
        clk,
        o_a11,o_a12,o_a21,o_a22,
        done);
input[31:0] i_a11,i_a12,i_a21,i_a22;
input start,reset,clk;
output [31:0]  o_a11,o_a12,o_a21,o_a22;
output reg done = 0;


parameter s_idle =3'b000;
parameter s_setup =3'b001;
parameter s_add =3'b010;
parameter s_reset = 3'b011;
parameter s_wait = 3'b100;

reg [2:0] state=s_idle;

wire add_ready;
wire [3:0] add_readies;
wire [31:0] result11,result12,result21,result22;
reg [31:0] acc11=0,acc12=0,acc21=0,acc22=0;
reg [31:0] a11,a12,a21,a22;
assign o_a11 = acc11;
assign o_a12 = acc12;
assign o_a21 = acc21;
assign o_a22 = acc22;

assign add_ready = & add_readies;

reg add_reset = 1;


reg a_stb,b_stb,z_ack;

always @(posedge clk) begin
    
    if(reset)begin
        state <= s_reset;
        add_reset <= 1;
    end
	 else begin
		 case (state)
			  s_idle: begin
					done <= 0;
					z_ack <= 0;
					add_reset <= 1;
					
					if (start) begin
						 state <= s_setup;
						 a11 <= i_a11; 
						 a12 <= i_a12; 
						 a21 <= i_a21; 
						 a22 <= i_a22; 
						 add_reset <= 1;
					end
			  end
			  s_setup: begin
						 state <= s_add;
						 a_stb <= 1;
                         b_stb <= 1;
                         z_ack <= 1;
						 add_reset <= 0;
			  end
			  s_add: begin
					z_ack <= 0;
					if (add_ready) begin
						acc11 <= result11;
					    acc12 <= result12;
					    acc21 <= result21;
					    acc22 <= result22;
						state <= s_wait; 
						done <= 1;
						a_stb <= 0;
                        b_stb <= 0;
                        z_ack <= 0;
					end
			  end
			  s_wait: begin
					state <= s_idle;
			  end
			  s_reset: begin
					state <= s_idle;
					acc11 <= 0;
					acc12 <= 0;
					acc21 <= 0;
					acc22 <= 0;
			  end
		 endcase
	end
end



adder addder_acc11(
    .clk(clk),
    .rst(add_reset),
    .input_a(acc11),
    .input_b(a11),
    .output_z(result11),
    .output_z_stb(add_readies[0]),
    .input_a_stb(a_stb),
    .input_b_stb(b_stb),
    .output_z_ack(z_ack)
);
adder addder_acc12(
    .clk(clk),
    .rst(add_reset),
    .input_a(acc12),
    .input_b(a12),
    .output_z(result12),
    .output_z_stb(add_readies[1]),
    .input_a_stb(a_stb),
    .input_b_stb(b_stb),
    .output_z_ack(z_ack)
);
adder addder_acc21(
    .clk(clk),
    .rst(add_reset),
    .input_a(acc21),
    .input_b(a21),
    .output_z(result21),
    .output_z_stb(add_readies[2]),
    .input_a_stb(a_stb),
    .input_b_stb(b_stb),
    .output_z_ack(z_ack)
);
adder addder_acc22(
    .clk(clk),
    .rst(add_reset),
    .input_a(acc22),
    .input_b(a22),
    .output_z(result22),
    .output_z_stb(add_readies[3]),
    .input_a_stb(a_stb),
    .input_b_stb(b_stb),
    .output_z_ack(z_ack)
);

endmodule

module test();

reg [31:0] a11,a12,a21,a22;
reg clk=0;
reg start;
reg reset = 0;
wire [31:0]  acc11,acc12,acc21,acc22;
wire done;
accumulator acc(
.i_a11(a11),
.i_a12(a12),
.i_a21(a21),
.i_a22(a22),
.clk(clk),
.reset(reset),
.start(start),
.o_a11(acc11),
.o_a12(acc12),
.o_a21(acc21),
.o_a22(acc22),
.done(done)
);
  always #10 clk=~clk;  // 25MHz
initial 
 $monitor ("%0t acc11=%h acc12=%h acc21=%h acc22=%h a11=%h a12=%h a21=%h a22=%h state=%d ready_add=%b done=%b",$time, acc11,acc12,acc21,acc22,a11,a12,a21,a22,acc.state,acc.add_ready,done);

initial begin
    start = 1;
    a11 = 32'h41f0f5c3;  //30.12
    a12 = 32'h42ee999a;  //119.3
    a21 = 32'h3ee66666;  //0.45
    a22 = 32'h4158a3d7;  //13.54
    #400
 
    start = 1;
    #1000
    $finish;
end
endmodule
