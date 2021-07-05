module matrix_mul_cu     #(parameter data_w = 32,
									parameter ram_d = 512,
									parameter ram_add_w = $clog2(ram_d),
									parameter d_w_q = data_w/4)
									
								  (input wire clk,rst,
								   input wire [data_w-1:0] c_11,c_12,c_21,c_22,
									input wire done_mac,
									input wire [data_w-1:0] ram_r_data,
									input wire start,
									output wire start_mac,
									output wire [data_w-1:0] a_11,a_12,a_21,a_22,
								                            b_11,b_12,b_21,b_22,
									output wire ram_we,
									output wire done,err,
									output wire [data_w-1:0] ram_w_data,
									output wire [ram_add_w-1:0] ram_addr);

// RAM format:									
// 0: [8 bit M1][8 bit N1][8 bit M2][8 bit N2]
// 1: reserved for metadata

reg [4:0] r_state;//machine state

reg [d_w_q-1:0] r_M1;
reg [d_w_q-1:0] r_N1;
reg [d_w_q-1:0] r_M2;
reg [d_w_q-1:0] r_N2;

reg [d_w_q-1:0] r_counter_i;
reg [d_w_q-1:0] r_counter_j;
reg [d_w_q-1:0] r_counter_k;

reg [ram_add_w-1:0] r_addr_a11;
reg [ram_add_w-1:0] r_addr_a21;
reg [ram_add_w-1:0] r_addr_b11;
reg [ram_add_w-1:0] r_addr_b21;
reg [ram_add_w-1:0] r_addr_c11;
reg [ram_add_w-1:0] r_addr_c21;

reg [d_w_q-1:0] r_limit_i;
reg [d_w_q-1:0] r_limit_j;
reg [d_w_q-1:0] r_limit_k;

// i neshon mide row e chandom az matrix chapi hastim
// j neshon mide col e chandom az matrix rasti hastim
// k counter e sevom hast (col e chap = row e rast)

reg       r_done;
reg 		 r_err;
reg       r_ram_we;
reg [data_w-1:0] r_ram_w_data;
reg [ram_add_w-1:0] r_ram_addr;
reg [data_w-1:0] r_a_11,r_a_12,r_a_21,r_a_22,
					  r_b_11,r_b_12,r_b_21,r_b_22;
reg		 r_start_mac;

assign done = r_done;
assign err = r_err;
assign ram_we = r_ram_we;
assign ram_w_data = r_ram_w_data;
assign ram_addr = r_ram_addr;
assign start_mac = r_start_mac;

assign a_11 = r_a_11;
assign a_12 = r_a_12;
assign a_21 = r_a_21;
assign a_22 = r_a_22;
assign b_11 = r_b_11;
assign b_12 = r_b_12;
assign b_21 = r_b_21;
assign b_22 = r_b_22;

parameter STATE_IDLE 		 = 5'h0;
parameter STATE_INIT 		 = 5'h1;
parameter STATE_RA11			 = 5'h2;
parameter STATE_RA12			 = 5'h3;
parameter STATE_RA21			 = 5'h4;
parameter STATE_RA22			 = 5'h5;
parameter STATE_RB11			 = 5'h6;
parameter STATE_RB12			 = 5'h7;
parameter STATE_RB21			 = 5'h8;
parameter STATE_RB22			 = 5'h9;

parameter STATE_CLIMIT	    = 5'h14;


always @ (posedge clk)
begin

	if(rst) begin
		r_state <= STATE_IDLE
	end
	else    begin
		case (r_state)
				
				STATE_IDLE:
				begin
					r_ram_we <= 'b0;
					r_ram_addr <= 'b0; //to prepare parameters
					r_start_mac <= 'b0;
					
					if(start)
						state <= STATE_INIT;
					else
						state <= STATE_IDLE;
				end
				
				STATE_INIT:
				begin
					//inja addr e ram 0 bode kafie read konim
					r_M1 <= ram_r_data[d_w_q*4-1:d_w_q*3];
					r_N1 <= ram_r_data[d_w_q*3-1:d_w_q*2];
					r_M2 <= ram_r_data[d_w_q*2-1:d_w_q];
					r_N2 <= ram_r_data[d_w_q-1:0];
					
					r_limit_i <= (ram_r_data[d_w_q*4-1:d_w_q*3] + 1'b1) >>> 1'b1;
					r_limit_j <= (ram_r_data[d_w_q-1:0]   + 1'b1) >>> 1'b1;
					r_limit_k <= (ram_r_data[d_w_q*2-1:d_w_q]  + 1'b1) >>> 1'b1;
					
					r_err <= 'b0;
					r_done <= 'b0;
					r_counter_i <= 'b0;
					r_counter_j <= 'b0;
					r_counter_k <= 'b0;
					
					r_addr_a11 <= 9'd2;
					r_addr_a21 <= 9'd2 + ram_r_data[d_w_q*4-1:d_w_q*3];
					r_addr_b11 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_addr_b21 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];

					r_state <= STATE_RA11;
				end
				
				STATE_RA11:
				begin
					if(N1!=M2) begin
						r_err <= 1'b1;	//raise error
						r_state <= STATE_IDLE;
					end 
					else if(r_limit_i == r_counter_i) begin
						r_state <= STATE_CLIMIT;
					end
					else 	begin
						
						// HOSH! inja bayad address haye a11 ina update beshe !!
						
						r_ram_addr <= r_addr_a11;
						r_state <= STATE_RA12;
					end
				end
				
				STATE_RA12:
				begin
					r_a11 <= ram_r_data;
					if(r_limit_k==r_counter_k && r_M1[0]) begin
						//yani in ab'ad e matrice fard bode va be tah residim, 0 por mikonim
						r_a12 <= 'b0;
						r_ram_addr <= r_addr_a21;
						r_state <= STATE_RA22;
					end
					else begin
						r_state <= STATE_RA21;
						r_ram_addr <= r_addr_a12;
					end
				end
				
				STATE_RA21:
				begin
					if(r_limit_i==r_counter_i &&
				end
				
				STATE_RA22:
				begin
				
				end
				
				STATE_RB11:
				begin
				
				end
				
				STATE_RB12:
				begin
				
				end
				
				STATE_RB21:
				begin
				
				end
				
				STATE_RB22:
				begin
				
				end
			
		endcase
	end
end

endmodule