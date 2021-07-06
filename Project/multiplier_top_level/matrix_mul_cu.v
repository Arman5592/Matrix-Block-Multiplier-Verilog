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
reg [data_w-1:0] r_a11,r_a12,r_a21,r_a22,
					  r_b11,r_b12,r_b21,r_b22;
reg		 r_start_mac;

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
parameter STATE_WRITEBACK   = 5'hE;

parameter STATE_CLIMIT	    = 5'h14;


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
					
					r_limit_i <= (ram_r_data[d_w_q*4-1:d_w_q*3] + 1'b1) >>> 1'b1;
					r_limit_j <= (ram_r_data[d_w_q-1:0]   + 1'b1) >>> 1'b1;
					r_limit_k <= (ram_r_data[d_w_q*2-1:d_w_q]  + 1'b1) >>> 1'b1;
					
					r_err <= 'b0;
					r_done <= 'b0;
					r_counter_i <= 'b0;
					r_counter_j <= 'b0;
					r_counter_k <= 'b0;
					
					r_addr_a11 <= 9'd2;
					r_addr_a12 <= 9'd3;
					r_addr_a21 <= 9'd2 + ram_r_data[d_w_q*4-1:d_w_q*3];
					r_addr_a22 <= 9'd3 + ram_r_data[d_w_q*4-1:d_w_q*3];
					r_addr_b11 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_addr_b12 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]);
					r_addr_b21 <= 9'd2 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];
					r_addr_b22 <= 9'd3 + (ram_r_data[d_w_q*4-1:d_w_q*3] * ram_r_data[d_w_q*3-1:d_w_q*2]) 
										    + ram_r_data[d_w_q*2-1:d_w_q];
										
					r_addr_c11 <= ram_d;

					r_state <= STATE_RA11;
				end
				
				
				
				STATE_RA11:
				begin
					if(r_N1!=r_M2) begin
						r_err <= 1'b1;	//raise error
						r_state <= STATE_IDLE;
					end 
					else if(r_limit_i == r_counter_i) begin
						r_state <= STATE_CLIMIT;
					end
					else 	begin
						
						
						r_ram_addr <= r_addr_a11;
						r_state <= STATE_RA12;
					end
				end
				
				
				
				STATE_RA12:
				begin
					r_a11 <= ram_r_data;
					r_state <= STATE_RA21;
					r_ram_addr <= r_addr_a12;
				end
				
				
				
				STATE_RA21:
				begin
					
					if(r_limit_k==r_counter_k && r_M1[0])
						r_a12 <= 'b0;
					else 
						r_a12 <= ram_r_data;
						
						r_state <= STATE_RA22;
						r_ram_addr <= r_addr_a21;
				end
				
				
				
				STATE_RA22:
				begin
					
					if(r_limit_i==r_counter_i && r_N1[0]) 
						r_a21 <= 'b0;
					else
						r_a21 <= ram_r_data;
					
						r_state <= STATE_RB11;
						r_ram_addr <= r_addr_a22;
				end
				
				
				
				STATE_RB11:
				begin
				
					if((r_limit_i==r_counter_i && r_N1[0]) || r_limit_k==r_counter_k && r_M1[0])
						r_a22 <= 'b0;
					else
						r_a22 <= ram_r_data;
						
					r_ram_addr <= r_addr_b11;
					r_state <= STATE_RB12;
				end
				
				STATE_RB12:
				begin
					r_b11 <= ram_r_data;
					r_state <= STATE_RB21;
					r_ram_addr <= r_addr_b12;	
				end
				
				
				
				STATE_RB21:
				begin
					if(r_limit_j==r_counter_j && r_M2[0])
						r_b12 <= 'b0;
					else
						r_b12 <= ram_r_data;
						
						r_state <= STATE_RB22;
						r_ram_addr <= r_addr_b21;
					
				end
				
				STATE_RB22:
				begin
					
					if(r_limit_k==r_counter_k && r_N2[0])
						r_b21 <= 'b0;
					else
						r_b21 <= ram_r_data;
						r_state <= STATE_BEGINMAC;
						r_ram_addr <= r_addr_b22;
					
					
				end
				
				
				STATE_BEGINMAC:
				begin
					
					if((r_limit_k==r_counter_k && r_N2[0]) || r_limit_j==r_counter_j && r_M2[0])
						r_b22 <= 'b0;
					else
						r_b22 <= ram_r_data;

					r_start_mac <= 1'b1;//start multiplication & accumulation (2x2)
					r_state <= STATE_WAIT;
					r_delay <= 5'd23;
					
					//HOSH! inja bayad update beshan address ha o ina <= injaro anjam bedam avalin kar / badesh ye run begiram bebinam addressa dorostan ya na
					if(r_counter_k == r_limit_k) begin
					
						if(r_counter_j == r_limit_j) begin
							r_counter_j <= 'b0;
							r_counter_i <= r_counter_i + 1'b1;
						end
						
						else begin
							r_counter_k <= 'b0;
							r_counter_j <= r_counter_j + 1'b1;
						end
						
					end
					
				end
				
				//inja mishe eyne adam omad ye seri load e dge anjam dad.
				STATE_WAIT:
				begin
					if((|r_delay)==1'b0) begin
						r_state <= STATE_ACCUMULATE;
					end
					else begin
						r_delay <= r_delay - 1'b1;
						r_state <= STATE_WAIT;
					end
				end
				
				
				STATE_ACCUMULATE:
				begin
					//inja bayad be adder, adad bedim, ke baramon accumulate kone (bordar ro)
					
					r_delay <= 5'd6;
					r_state <= STATE_WAIT2;
				end
				
				STATE_WAIT2:
				begin
					if((|r_delay)==1'b0) begin
						//inja yeseri if darim, age lazem bod bere state e writeback, age na bargarde sare khone aval
					end
					else begin
						r_delay <= r_delay - 1'b1;
						r_state <= STATE_WAIT2;
					end
				end
				
				STATE_WRITEBACK:
				begin
				
				end
				
				
				default:
				begin
					r_state <= STATE_IDLE;
				end
			
		endcase
	end
end

endmodule
