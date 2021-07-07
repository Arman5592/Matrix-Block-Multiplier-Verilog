module matrix_multiplier #(parameter data_w = 32)
								  (input wire clk,rst,start,
								   output wire done,err);
						
wire [data_w-1:0] ram_r_data;
wire ram_we;
wire [8:0] ram_addr;

matrix_mul_cu control_unit (.clk(clk),
									 .rst(rst),
									 .ram_r_data(ram_r_data),
									 .start(start),
									 .ram_we(ram_we),
									 .done(done),
									 .err(err),
									 .ram_addr(ram_addr)
									 );
									 
ram			  memory			(.clk(clk),
									 .do(ram_r_data),
									 .addr(ram_addr),
									 .we(ram_we)
									 );

endmodule

								   