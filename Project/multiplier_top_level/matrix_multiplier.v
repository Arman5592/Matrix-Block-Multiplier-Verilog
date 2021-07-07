module matrix_multiplier #(parameter data_w = 32)
								  (input wire clk,rst,start,
								   output wire done,err);
						
wire [data_w-1:0] ram_r_data;
wire ram_we,done_mac,start_mac;
wire [8:0] ram_addr;
wire [data_w-1:0] a11,a12,a21,a22,
						b11,b12,b21,b22,
						c11,c12,c21,c22;

matrix_mul_cu 		control_unit(.clk(clk),
										 .rst(rst),
										 .ram_r_data(ram_r_data),
										 .start(start),
										 .ram_we(ram_we),
										 .done(done),
										 .err(err),
										 .ram_addr(ram_addr),
										 .done_mac(done_mac),
										 .start_mac(start_mac),
										 .a_11(a11),
										 .a_12(a12),
										 .a_21(a21),
										 .a_22(a22),
										 .b_11(b11),
										 .b_12(b12),
										 .b_21(b21),
										 .b_22(b22),
										 .c_11(c11),
										 .c_12(c12),
										 .c_21(c21),
										 .c_22(c22)
										 );
									 
ram			  		memory	(.clk(clk),
									 .do(ram_r_data),
									 .addr(ram_addr),
									 .we(ram_we)
									 );
									 
base_matrix_multiplier base(.clk(clk),
									 .i_a11(a11),
									 .i_a12(a12),
									 .i_a21(a21),
									 .i_a22(a22),
									 .i_b11(b11),
									 .i_b12(b12),
									 .i_b21(b21),
									 .i_b22(b22),
									 .o_c11(c11),
									 .o_c12(c12),
									 .o_c21(c21),
									 .o_c22(c22),
									 .start(start_mac),
									 .done(done_mac)
									 );

endmodule

								   