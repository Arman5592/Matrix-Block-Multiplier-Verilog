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

endmodule
