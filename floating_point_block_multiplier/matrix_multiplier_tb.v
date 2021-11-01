`timescale 1ps/1ps

module matrix_multiplier_tb ();


reg clk,rst,start;
wire done,error,block_complete,ram_w;

matrix_multiplier multiplier(clk,rst,start,done,error,ram_w,block_complete);

always begin
	clk = 'b1;
	#10;
	clk = 'b0;
	#10;
end

initial begin
	rst = 'b0;
	start = 'b0;
	#30;
	start = 'b1;
	#100;
	start = 1'b0;
end

endmodule
