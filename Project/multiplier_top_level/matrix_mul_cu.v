module matrix_mul_cu     #(parameter data_w = 32,
									parameter ram_d = 512,
									parameter ram_add_w = $clog2(ram_d),
									parameter d_w_q = data_w/4)
									
								  (input wire clk,rst,
								   input wire [data_w-1:0] c_11,c_12,c_21,c_22,
																   acc_11,acc_12,acc_21,acc_22,
									input wire done_mac,
									input wire [data_w-1:0] ram_r_data,
									input wire start,
									input wire done_acc,
									
									output wire start_mac,
									output wire reset_acc,
									output wire start_acc,
									output wire [data_w-1:0] a_11,a_12,a_21,a_22,
								                            b_11,b_12,b_21,b_22,
									output wire [data_w-1:0] res_11,res_12,res_21,res_22,
									output wire ram_we,
									output wire done,err,
									output wire block_mac_complete,
									output wire [data_w-1:0] ram_w_data,
									output wire [ram_add_w-1:0] ram_addr);

// RAM format:									
// 0: [8 bit M1][8 bit N1][8 bit M2][8 bit N2]
// 1: reserved for metadata

reg [4:0] r_state;//machine state
reg [4:0] r_delay;//for waiting intervals

reg [d_w_q-1:0] r_M1;
reg [d_w_q-1:0] r_N1;
reg [d_w_q-1:0] r_M2;
reg [d_w_q-1:0] r_N2;

reg [d_w_q-1:0] r_counter_i;
reg [d_w_q-1:0] r_counter_j;
reg [d_w_q-1:0] r_counter_k;

reg [ram_add_w-1:0] r_addr_a11;
reg [ram_add_w-1:0] r_addr_a12;
reg [ram_add_w-1:0] r_addr_a21;
reg [ram_add_w-1:0] r_addr_a22;
reg [ram_add_w-1:0] r_addr_b11;
reg [ram_add_w-1:0] r_addr_b12;
reg [ram_add_w-1:0] r_addr_b21;
reg [ram_add_w-1:0] r_addr_b22;
reg [ram_add_w-1:0] r_addr_c11;
reg [ram_add_w-1:0] r_addr_c12;
reg [ram_add_w-1:0] r_addr_c21;
reg [ram_add_w-1:0] r_addr_c22;

reg [ram_add_w-1:0] r_start_b11;
reg [ram_add_w-1:0] r_start_b12;
reg [ram_add_w-1:0] r_start_b21;
reg [ram_add_w-1:0] r_start_b22;

reg [d_w_q-1:0] r_limit_i;
reg [d_w_q-1:0] r_limit_j;
reg [d_w_q-1:0] r_limit_k;

reg r_writeback_flag = 1'b0;
reg r_init_cycle_flag = 1'b0;
reg r_even_width_A;
reg r_even_height_B;
reg [1:0] r_update_addr_c = 2'b00;

// i neshon mide row e chandom az matrix chapi hastim
// j neshon mide col e chandom az matrix rasti hastim
// k counter e sevom hast (col e chap = row e rast)

reg       r_done;
reg		 r_start_acc;
reg		 r_reset_acc;
reg 		 r_err;
reg       r_ram_we;
reg [data_w-1:0] r_ram_w_data;
reg [ram_add_w-1:0] r_ram_addr;
reg [data_w-1:0] r_a11,r_a12,r_a21,r_a22,
					  r_b11,r_b12,r_b21,r_b22,
					  r_res11,r_res12,r_res21,r_res22;
reg		 r_start_mac;

wire [d_w_q-1:0] w_2N2;

assign w_2N2 = r_N2 << 1'b1;
assign start_acc = r_start_acc;
assign reset_acc = r_reset_acc;
assign done = r_done;
assign err = r_err;
assign ram_we = r_ram_we;
assign ram_w_data = r_ram_w_data;
assign ram_addr = r_ram_addr;
assign start_mac = r_start_mac;
assign block_mac_complete = done_mac;

assign a_11 = r_a11;
assign a_12 = r_a12;
assign a_21 = r_a21;
assign a_22 = r_a22;
assign b_11 = r_b11;
assign b_12 = r_b12;
assign b_21 = r_b21;
assign b_22 = r_b22;
assign res_11 = r_res11;
assign res_12 = r_res12;
assign res_21 = r_res21;
assign res_22 = r_res22;


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
parameter STATE_BEGINMAC	 = 5'hA;
parameter STATE_WAIT			 = 5'hB;
parameter STATE_ACCUMULATE  = 5'hC;
parameter STATE_WAIT2		 = 5'hD;
parameter STATE_WRITEBACK11 = 5'hE;
parameter STATE_WRITEBACK12 = 5'hF;
parameter STATE_WRITEBACK21 = 5'h10;
parameter STATE_WRITEBACK22 = 5'h11;

parameter STATE_INIT2		 = 5'h12;//to increase operational frequency
parameter STATE_INIT3		 = 5'h13;

parameter STATE_RA11_P		 = 5'h14;//pipelined fetch stages vvv
parameter STATE_RA12_P		 = 5'h15;
parameter STATE_RA21_P		 = 5'h16;
parameter STATE_RA22_P		 = 5'h17;
parameter STATE_RB11_P		 = 5'h18;
parameter STATE_RB12_P		 = 5'h19;
parameter STATE_RB21_P		 = 5'h1A;
parameter STATE_RB22_P		 = 5'h1B;


parameter STATE_CLIMIT	    = 5'h1C;


parameter DELAY_MAC			 = 5'd23;
parameter DELAY_ACC			 = 5'd6; //HOSH! ina parameter e module beshe

always @ (posedge clk)
begin

	if(rst) begin
		r_state <= STATE_IDLE;
	end
	else    begin
		case (r_state)
				
				STATE_IDLE:
				begin
					r_ram_we <= 'b0;
					r_ram_addr <= 'b0; //to prepare parameters
					r_start_mac <= 'b0;
					
					if(start)
						r_state <= STATE_INIT;
					else
						r_state <= STATE_IDLE;
				end
				
				STATE_INIT:
				begin
					//inja addr e ram 0 bode kafie read konim
					r_M1 <= ram_r_data[d_w_q*4-1:d_w_q*3];
					r_N1 <= ram_r_data[d_w_q*3-1:d_w_q*2];
					r_M2 <= ram_r_data[d_w_q*2-1:d_w_q];
					r_N2 <= ram_r_data[d_w_q-1:0];
					
					r_limit_i <= ((ram_r_data[d_w_q*4-1:d_w_q*3] + 1'b1) >>> 1'b1);
					r_limit_j <= ((ram_r_data[d_w_q-1:0]   + 1'b1) >>> 1'b1)-1'b1;
					r_limit_k <= ((ram_r_data[d_w_q*2-1:d_w_q]  + 1'b1) >>> 1'b1)-1'b1;
					
					r_err <= 'b0;
					r_done <= 'b0;
					r_counter_i <= 'b0;
					r_counter_j <= 'b0;
					r_counter_k <= 'b0;
					
					r_addr_a11 <= 9'd2;
					r_addr_a12 <= 9'd3;
					r_addr_a21 <= 9'd2 + ram_r_data[d_w_q*3-1:d_w_q*2];
					r_addr_a22 <= 9'd3 + ram_r_data[d_w_q*3-1:d_w_q*2];
					
					
					r_addr_b11 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_addr_b21 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_addr_b12 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];
					r_addr_b22 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];
										
					r_addr_c11 <= ram_d - 1'b1;
					r_addr_c12 <= ram_d - 2'b10;
					r_addr_c21 <= ram_d - ram_r_data[d_w_q-1:0] - ram_r_data[0] - 1'b1;
					r_addr_c22 <= ram_d - ram_r_data[d_w_q-1:0] - ram_r_data[0] - 2'b10;
					
					r_start_b11 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_start_b21 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_start_b12 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];
					r_start_b22 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];

					r_state <= STATE_RA11;
					r_ram_addr <= 9'd2;
					r_ram_we <= 'b0;
					r_init_cycle_flag <= 1'b1;
					
					r_even_width_A <= ~ram_r_data[d_w_q*2];
					r_even_height_B <= ~ram_r_data[d_w_q];
				end
				
				
				
				STATE_RA11:
				begin
					
					if(r_N1!=r_M2) begin
						r_err <= 1'b1;	//raise error
						r_state <= STATE_IDLE;
					end 
					else if(r_limit_i == r_counter_i)
						r_state <= STATE_CLIMIT;
					else 	begin
						r_ram_addr <= r_addr_a12;
						r_state <= STATE_RA12;
					end
				end
				
				
				
				STATE_RA12:
				begin
					r_a11 <= ram_r_data;
					r_state <= STATE_RA21;
					r_ram_addr <= r_addr_a21;
					
					r_start_acc <= 1'b0;
				end
				
				
				
				STATE_RA21:
				begin
					r_reset_acc <= 1'b0;
					if(r_limit_k==r_counter_k && r_N1[0])
						r_a12 <= 'b0;
					else 
						r_a12 <= ram_r_data;
						
						r_state <= STATE_RA22;
						r_ram_addr <= r_addr_a22;
				end
				
				
				
				STATE_RA22:
				begin
					
					if(r_limit_i==(r_counter_i+1'b1) && r_M1[0]) 
						r_a21 <= 'b0;
					else
						r_a21 <= ram_r_data;
					
						r_state <= STATE_RB11;
						r_ram_addr <= r_addr_b11;
				end
				
				
				
				STATE_RB11:
				begin
				
					if((r_limit_i==(r_counter_i+1'b1) && r_M1[0]) || r_limit_k==r_counter_k && r_N1[0])
						r_a22 <= 'b0;
					else
						r_a22 <= ram_r_data;
						
					r_ram_addr <= r_addr_b12;
					r_state <= STATE_RB12;
				end
				
				STATE_RB12:
				begin
					r_b11 <= ram_r_data;
					r_state <= STATE_RB21;
					r_ram_addr <= r_addr_b21;	
				end
				
				
				
				STATE_RB21:
				begin
					if(r_limit_j==r_counter_j && r_N2[0])
						r_b12 <= 'b0;
					else
						r_b12 <= ram_r_data;
						
						r_state <= STATE_RB22;
						r_ram_addr <= r_addr_b22;
					
				end
				
				STATE_RB22:
				begin
					
					if(r_limit_k==r_counter_k && r_M2[0])
						r_b21 <= 'b0;
					else
						r_b21 <= ram_r_data;
						r_state <= STATE_BEGINMAC;
						r_ram_addr <= r_addr_b22;
					
					
				end
				
				
				STATE_BEGINMAC:
				begin
					
					if((r_limit_k==r_counter_k && r_M2[0]) || r_limit_j==r_counter_j && r_N2[0])
						r_b22 <= 'b0;
					else
						r_b22 <= ram_r_data;
					
					r_start_mac <= 1'b1;//start multiplication & accumulation (2x2)
					r_state <= STATE_WAIT;
					r_delay <= DELAY_MAC;
					r_init_cycle_flag <= 1'b0;

					r_counter_k <= r_counter_k + 1'b1;
					
					if(r_counter_k == r_limit_k && (!r_init_cycle_flag)) begin 
					
						if(r_counter_j == r_limit_j) begin  //inja yani i ziad shode 
						
							r_counter_k <= 'b0;
							r_counter_j <= 'b0;
							r_counter_i <= r_counter_i + 1'b1;
							
							r_addr_a11 <= r_addr_a22 + r_even_width_A; 
							r_addr_a12 <= r_addr_a22 + r_even_width_A + 1'b1;
							r_addr_a21 <= r_addr_a22 + r_N1 + r_even_width_A;
							r_addr_a22 <= r_addr_a22 + r_N1 + r_even_width_A + 1'b1;
							
							r_addr_b11 <= r_start_b11;
							r_addr_b12 <= r_start_b12;
							r_addr_b21 <= r_start_b21;
							r_addr_b22 <= r_start_b22;
							
							
							r_update_addr_c <= 2'b10;
								
							
						end
						
						else begin //inja yani j ziad shode
							r_counter_k <= 'b0;
							r_counter_j <= r_counter_j + 1'b1;
							
							r_addr_a11 <= r_addr_a11 - r_N1 + r_even_width_A + 1'b1;
							r_addr_a12 <= r_addr_a12 - r_N1 + r_even_width_A + 1'b1;
							r_addr_a21 <= r_addr_a21 - r_N1 + r_even_width_A + 1'b1;
							r_addr_a22 <= r_addr_a22 - r_N1 + r_even_width_A + 1'b1;
						
							r_addr_b11 <= r_addr_b22 + r_even_height_B;
							r_addr_b12 <= r_addr_b22 + r_M2 + r_even_height_B;
							r_addr_b21 <= r_addr_b22 + r_even_height_B + 1'b1;
							r_addr_b22 <= r_addr_b22 + r_M2 + r_even_height_B + 1'b1;
							
							r_update_addr_c <= 2'b01;	
								
						end
						
					end else begin // inja yani k ziad shode
						r_update_addr_c <= 2'b00;
						
						r_addr_a11 <= r_addr_a12 + 1'b1;
						r_addr_a12 <= r_addr_a12 + 2'b10;
						r_addr_a21 <= r_addr_a22 + 1'b1;
						r_addr_a22 <= r_addr_a22 + 2'b10;
						
						r_addr_b11 <= r_addr_b21 + 1'b1;
						r_addr_b12 <= r_addr_b22 + 1'b1;
						r_addr_b21 <= r_addr_b21 + 2'b10;
						r_addr_b22 <= r_addr_b22 + 2'b10;
					end
				end
				
				//inja mishe eyne adam omad ye seri load e dge anjam dad.
				STATE_WAIT:
				begin
					//if((|r_delay)==1'b0) begin
					if(done_mac) begin
						r_state <= STATE_ACCUMULATE;
						
						r_res11 <= c_11;
						r_res12 <= c_12;
						r_res21 <= c_21;
						r_res22 <= c_22;
						
					end
					else if(r_delay == 5'b10110) begin
						r_start_mac <= 1'b0;
						r_delay <= r_delay - 1'b1;
						r_state <= STATE_WAIT;
					end
					else begin
						r_delay <= r_delay - 1'b1;
						r_state <= STATE_WAIT;
					end
				end
				
				
				STATE_ACCUMULATE:
				begin
					
					
					if(r_counter_k == r_limit_k) begin
						r_writeback_flag <= 1'b1;
					end
					
					if(r_writeback_flag) begin
						r_writeback_flag <= 1'b0;
						r_state <= STATE_WAIT2;
						r_delay <= DELAY_ACC;
					end
					else begin
						r_ram_addr <= r_addr_a11;
						r_state <= STATE_RA11;//badan bere stage haye pipeline shode
					end
						
					
						
					r_start_acc <= 1'b1;

					
				end
				
				STATE_WAIT2:
				begin
					//if((|r_delay)==1'b0) begin
					if(done_acc) begin
						r_state <= STATE_WRITEBACK11;
						r_ram_we <= 'b1;
						r_ram_addr <= r_addr_c11;
						r_ram_w_data <= acc_11;
					end
					
					else begin
						r_delay <= r_delay - 1'b1;
						r_state <= STATE_WAIT2;
					end
				end
				
				
				STATE_WRITEBACK11:
				begin
					r_ram_addr <= r_addr_c12;
					r_ram_w_data <= acc_12;
					r_state <= STATE_WRITEBACK12;
				end
				
				STATE_WRITEBACK12:
				begin
					r_ram_addr <= r_addr_c21;
					r_ram_w_data <= acc_21;
					r_state <= STATE_WRITEBACK21;
				end
				
				STATE_WRITEBACK21:
				begin
					r_ram_addr <= r_addr_c22;
					r_ram_w_data <= acc_22;
					r_state <= STATE_WRITEBACK22;
				end
				
				STATE_WRITEBACK22:
				begin
					r_ram_addr <= r_addr_a11;
					r_state <= STATE_RA11;
					r_ram_we <= 'b0;
					r_reset_acc <= 1'b1;
					r_update_addr_c <= 2'b00;
					
					if(r_update_addr_c == 2'b10) begin
						r_addr_c11 <= r_addr_c11 - {r_N2[d_w_q-1:1],1'b0} - 2'b10;
						r_addr_c12 <= r_addr_c12 - {r_N2[d_w_q-1:1],1'b0} - 2'b10;
						r_addr_c21 <= r_addr_c21 - {r_N2[d_w_q-1:1],1'b0} - 2'b10;
						r_addr_c22 <= r_addr_c22 - {r_N2[d_w_q-1:1],1'b0} - 2'b10;
					end else if (r_update_addr_c == 2'b01) begin
						r_addr_c11 <= r_addr_c11 - 2'b10;
						r_addr_c12 <= r_addr_c12 - 2'b10;
						r_addr_c21 <= r_addr_c21 - 2'b10;
						r_addr_c22 <= r_addr_c22 - 2'b10;
					end	
				end
				
				STATE_CLIMIT:
				begin
					r_done <= 1'b1;
					r_state <= STATE_IDLE;
				end
				
				
				default:
				begin
					r_state <= STATE_IDLE;//'self-starting'
				end
				
				//pipeline fetching stages:
				
				STATE_RA11_P:
				begin
				
				end
				
				STATE_RA12_P:
				begin
				
				end
				
				STATE_RA21_P:
				begin
				
				end
				
				STATE_RA22_P:
				begin
				
				end
			
		endcase
	end
end

endmodule
