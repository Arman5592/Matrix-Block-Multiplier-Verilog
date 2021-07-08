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


parameter s_idle =2'b00;
parameter s_setup =2'b01;
parameter s_add =2'b10;
reg [1:0] state=s_idle;

reg add_ack=0;
wire add_ready;
wire [31:0] result11,result12,result21,result22;

reg [31:0] acc11=0,acc12=0,acc21=0,acc22=0;
reg [31:0] a11,a12,a21,a22;
assign o_a11 = acc11;
assign o_a12 = acc12;
assign o_a21 = acc21;
assign o_a22 = acc22;

always @(posedge clk) begin
    
    if(reset)begin
        state <= s_idle;
        acc11 <= 0;
        acc12 <= 0;
        acc21 <= 0;
        acc22 <= 0;
    end
	 else begin

		 case (state)
			  s_idle: begin
					done <= 0;
					add_ack <= 0;
					if (start) begin
						 state <= s_setup;
						 a11 <= i_a11; 
						 a12 <= i_a12; 
						 a21 <= i_a21; 
						 a22 <= i_a22; 
					end
			  end
			  s_setup: begin
						 state <= s_add;
						 add_ack <= 1;
			  end
			  s_add: begin
					add_ack <= 0;
					if (add_ready) begin
						 state <= s_idle;
						 done <= 1;
						 acc11 <= result11;
						 acc12 <= result12;
						 acc21 <= result21;
						 acc22 <= result22;
					end
			  end
		 endcase     
	end
end



adder adder_acc11(
    .clk(clk),
    .reset(state==s_idle || state==s_add),
    .load(1'b1),
    .Number1(acc11),
    .Number2(a11),
    .result_ack(add_ack),
    .Result(result11),
    .result_ready(add_ready)
);
adder adder_acc12(
    .clk(clk),
    .reset(state==s_idle || state==s_add),
    .load(1'b1),
    .Number1(acc12),
    .Number2(a12),
    .result_ack(add_ack),
    .Result(result12),
    .result_ready(add_ready)
);
adder adder_acc21(
    .clk(clk),
    .reset(state==s_idle || state==s_add),
    .load(1'b1),
    .Number1(acc21),
    .Number2(a21),
    .result_ack(add_ack),
    .Result(result21),
    .result_ready(add_ready)
);
adder adder_acc22(
    .clk(clk),
    .reset(state==s_idle || state==s_add),
    .load(1'b1),
    .Number1(acc22),
    .Number2(a22),
    .result_ack(add_ack),
    .Result(result22),
    .result_ready(add_ready)
);

endmodule

module test();

reg [31:0] a11,a12,a21,a22;
reg clk=0;
reg start;
reg reset = 0;
wire [31:0]  acc11,acc12,acc21,acc22;
wire done;
accumalator acc(
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
 $monitor ("%0t acc11=%h acc12=%h acc21=%h acc22=%h a11=%h a12=%h a21=%h a22=%h state=%d ready_add=%b",$time, acc11,acc12,acc21,acc22,a11,a12,a21,a22,acc.state,acc.add_ready);

initial begin
    start = 1;
    a11 = 32'h41f0f5c3;  //30.12
    a12 = 32'h42ee999a;  //119.3
    a21 = 32'h3ee66666;  //0.45
    a22 = 32'h4158a3d7;  //13.54
    // c11=3705.5608    0x456798f8 
    // c12=1939.51      0x44f27050
    // c21=149.423      0x43156c49
    // c22=211.22       0x43533850
    #400
    reset=1;
    start = 0;
    #100
    $finish;
end
endmodule
