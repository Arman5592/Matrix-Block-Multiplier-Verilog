`timescale 1ps/1ps
`define MANUAL

module ram #(parameter width=8,
             parameter depth=512,
				 parameter dlog = $clog2(depth))
				(input wire we,clk,
				 input wire [width-1:0] data,
				 input wire [dlog-1:0] addr,
				 output reg [width-1:0] do);

				 
reg [width-1:0] mem [depth-1:0];
integer f=0,i=0;

always @ (posedge clk) begin
	
	if(we) begin
		do <= data;
		mem[addr] <= data;
	end else
		do <= mem[addr];
end

`ifndef MANUAL
initial
begin
    $readmemb("input.txt", mem);

    #10000;

    f = $fopen("output.txt","w");

      for (i = 511; i>=0; i=i-1) begin
        $fwrite(f,"%b\n",mem[i]);
     end

     $fclose(f);
end
`endif
`ifdef MANUAL
initial
begin
	
end
`endif

endmodule
