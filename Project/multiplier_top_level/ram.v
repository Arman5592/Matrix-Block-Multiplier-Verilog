module ram #(parameter width=32,
             parameter depth=512,
				 parameter dlog = $clog2(depth))
				(input wire we,clk,
				 input wire [width-1:0] data,
				 input wire [dlog-1:0] addr,
				 output reg [width-1:0] do);

				 
reg [width-1:0] mem [depth-1:0];

always @ (posedge clk) begin
	
	if(we) begin
		do <= data;
		mem[addr] <= data;
	end else
		do <= mem[addr];
end

initial
begin
	mem[0] = {8'd4,8'd4,8'd4,8'd2};
	mem[1] = 32'h00000000;
	
	mem[2] = 32'h00000000;
	mem[3] = 32'h00000000;
	mem[4] = 32'h00000000;
	mem[5] = 32'h00000000;
	
	mem[6] = 32'h00000000;
	mem[7] = 32'h00000000;
	mem[8] = 32'h00000000;
	mem[9] = 32'h00000000;
	
	mem[10] = 32'h00000000;
	mem[11] = 32'h00000000;
	mem[12] = 32'h00000000;
	mem[13] = 32'h00000000;
	
	mem[14] = 32'h00000000;
	mem[15] = 32'h00000000;
	mem[16] = 32'h00000000;
	mem[17] = 32'h00000000;
	
	//
	
	mem[18] = 32'h00000000;
	mem[19] = 32'h00000000;
	mem[20] = 32'h00000000;
	mem[21] = 32'h00000000;
	
	mem[22] = 32'h00000000;
	mem[23] = 32'h00000000;
	mem[24] = 32'h00000000;
	mem[25] = 32'h00000000;
end

endmodule
