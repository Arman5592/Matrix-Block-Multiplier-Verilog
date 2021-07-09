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

reg add_ack=0;
wire add_ready;
wire add_ready11,add_ready12,add_ready21,add_ready22;
wire [31:0] result11,result12,result21,result22;
reg [31:0] acc11=0,acc12=0,acc21=0,acc22=0;
reg [31:0] a11,a12,a21,a22;
assign o_a11 = acc11;
assign o_a12 = acc12;
assign o_a21 = acc21;
assign o_a22 = acc22;

assign add_ready = add_ready11 & add_ready12 & add_ready21 & add_ready22;

reg add_reset = 1;
reg add_load = 0;

always @(posedge clk) begin
    
    if(reset)begin
        state <= s_reset;
        add_reset <= 0;
        add_load <= 0;
		  
    end
	 else begin
		 case (state)
			  s_idle: begin
					done <= 0;
					add_ack <= 0;
					add_reset <= 0;
					add_load <= 0;
					
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
						 add_load <= 1;
						 add_reset <= 1;
			  end
			  s_add: begin
					add_ack <= 0;
					acc11 <= result11;
					acc12 <= result12;
					acc21 <= result21;
					acc22 <= result22;
					if (add_ready) begin
						 state <= s_wait; 
						 done <= 1;
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




adder adder_acc11(
    .clk(clk),
    .reset(add_reset),
    .load(add_load),
    .Number1(acc11),
    .Number2(a11),
    .result_ack(add_ack),
    .Result(result11),
    .result_ready(add_ready11)
);
adder adder_acc12(
    .clk(clk),
    .reset(add_reset),
    .load(add_load),
    .Number1(acc12),
    .Number2(a12),
    .result_ack(add_ack),
    .Result(result12),
    .result_ready(add_ready12)
);
adder adder_acc21(
    .clk(clk),
    .reset(add_reset),
    .load(add_load),
    .Number1(acc21),
    .Number2(a21),
    .result_ack(add_ack),
    .Result(result21),
    .result_ready(add_ready21)
);
adder adder_acc22(
    .clk(clk),
    .reset(add_reset),
    .load(add_load),
    .Number1(acc22),
    .Number2(a22),
    .result_ack(add_ack),
    .Result(result22),
    .result_ready(add_ready22)
);

endmodule

