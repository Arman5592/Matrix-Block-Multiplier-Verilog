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
	mem[0] = {8'd3,8'd3,8'd3,8'd3};
	mem[1] = 32'h00000000;
	
	mem[2] = 32'h3f99999a;
	mem[3] = 32'h3fa66666;
	mem[4] = 32'h3fb33333;
	mem[5] = 32'h3fc00000;
	
	mem[6] = 32'h3fcccccd;
	mem[7] = 32'h3fd9999a;
	mem[8] = 32'h3fe66666;
	mem[9] = 32'h3ff33333;
	
	mem[10] = 32'h40000000;
	mem[11] = 32'h40066666;
	mem[12] = 32'h400ccccd;
	mem[13] = 32'h40133333;
	
	mem[14] = 32'h4019999a;
	mem[15] = 32'h40200000;
	mem[16] = 32'h40266666;
	mem[17] = 32'h402ccccd;
	
	//
	
	mem[18] = 32'h40333333;
	mem[19] = 32'h4039999a;
	mem[20] = 32'h40400000;
	mem[21] = 32'h40466666;
	
	mem[22] = 32'h404ccccd;
	mem[23] = 32'h40533333;
	mem[24] = 32'h4059999a;
	mem[25] = 32'h40600000;
end

endmodule
