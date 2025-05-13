module RsaCore (
	input          clk,
	input          rst_n,
	input          i_start,
	input  [15:0]  i_number,         // cipher text y
	input  [15:0]  i_key,         // private key
	input  [15:0]  i_n,
	output [15:0]  o_result,   // plain text x
	output         o_finished,
	output		   o_busy
);

localparam S_IDLE = 2'd0;
localparam S_PREP = 2'd1;
localparam S_MONT = 2'd2;
localparam S_CALC = 2'd3;

reg [15:0] number,    number_w;
reg [15:0] key, 	  key_w;
reg [19:0] n, 		  n_w;

reg [1:0]  state,     state_w;
reg 	   RsaPrep,   RsaPrep_w; 
reg [4:0]  countC,    countC_w;
reg [4:0]  countM, 	  countM_w;		//for mont to iterate through bits
reg [4:0]  countP, 	  countP_w;
reg 	   mont, 	  mont_w;		//which mont we are running

// calculation operands
reg [19:0] m, 		  m_w;		    //answer of problem
reg [19:0] t, 	      t_w;		    //operand of mont function
reg [19:0] k, 		  k_w;		    //operand in modulo function
reg [19:0] mont1a,    mont1a_w;
reg [19:0] mont1b,    mont1b_w;
reg [19:0] monttemp1, monttemp1_w;
reg [19:0] mont2a,    mont2a_w;
reg [19:0] mont2b, 	  mont2b_w;
reg [19:0] monttemp2, monttemp2_w;

reg [15:0] result, 	  result_w;
reg 	   finish, 	  finish_w;

assign	o_result   = result;
assign	o_finished = finish;
assign  o_busy	   = (i_start || state != S_IDLE) ? 1'b1 : 1'b0;

// Load input
always@(*)begin
	if (i_start) begin
		number_w = i_number;
		key_w = i_key;
		n_w = {4'd0, i_n};
	end
	else begin
		number_w = number;
		key_w = key;
		n_w = n;
	end
end

// FSM
always@(*) begin
    state_w = state;

	case(state)
		S_IDLE: begin
			if(i_start) begin
				state_w = S_PREP;
			end
		end
		S_PREP: begin
			if(RsaPrep == 1'd0) begin
				state_w = S_CALC;
			end
		end
		S_MONT: begin
			if(countM == 5'd17) begin
				state_w = S_CALC;
			end
		end
		S_CALC: begin
			if(countC < 5'd16) begin
				state_w = S_MONT;
			end
			else begin
				state_w = S_IDLE;
			end
		end
		default : begin
		end
	endcase
end

// Montgomery algorithm
always@(*) begin
    RsaPrep_w 	= RsaPrep;
    countC_w 	= countC;
    countM_w 	= countM;
    countP_w 	= countP;
    mont_w 		= mont;
    m_w 		= m;
    t_w 		= t;
    k_w 		= k;
    mont1a_w 	= mont1a;
    mont1b_w    = mont1b;
    mont2a_w    = mont2a;
    mont2b_w    = mont2b;
    monttemp1_w = monttemp1;
    monttemp2_w = monttemp2;
    result_w 	= result;
    finish_w 	= 1'b0;

	case(state)
		S_IDLE: begin
			if(i_start) begin
				k_w   	  = {4'd0, i_number};
				t_w 	  = 20'd0;
				RsaPrep_w = 1'b1;
			end
		end
		S_PREP: begin
			RsaPrep_w = 1'd1;
			if (k >= n) begin
				k_w = k - n;
			end
			else if(countP != 5'd17) begin
				if(countP == 5'd16) begin
					if(t + k >= n)
						t_w = t + k - n;
					else 
						t_w = t + k;
				end
				if(k + k >= n) begin
					k_w = k + k - n;
				end
				else begin
					k_w = k + k;
				end
				countP_w = countP + 5'd1;
			end
			else begin
				RsaPrep_w = 1'd0;
			end
			if (RsaPrep == 0) begin
				countC_w = 5'd0;
				m_w      = 20'd1;
				countP_w = 5'd0;
			end
		end
		S_MONT: begin
			//if ith bit of d is 1, calculate two monts in parellel
			if(mont == 1'd1) begin
				if(countM < 5'd16) begin
					if(mont1a[countM] == 1'b1 && ((monttemp1[0] == 1'b1 && mont1b[0] == 1'b0) || (monttemp1[0] == 1'b0 && mont1b[0] == 1'b1))) begin		//m + b is odd
						monttemp1_w = (monttemp1 + mont1b + n) >> 1;
					end
					else if(mont1a[countM] == 1'b1 && ((monttemp1[0] == 1'b1 && mont1b[0] == 1'b1) || (monttemp1[0] == 1'b0 && mont1b[0] == 1'b0))) begin		//m + b is even
						monttemp1_w = (monttemp1 + mont1b) >> 1;
					end
					else if(mont1a[countM] != 1'b1 && monttemp1[0] == 1'b1) begin
						monttemp1_w = (monttemp1 + n) >> 1;
					end
					else begin
						monttemp1_w = monttemp1 >> 1;
					end
					if(mont2a[countM] == 1'b1 && ((monttemp2[0] == 1'b1 && mont2b[0] == 1'b0) || (monttemp2[0] == 1'b0 && mont2b[0] == 1'b1))) begin		//m + b is odd
						monttemp2_w = (monttemp2 + mont2b + n) >> 1;
					end
					else if(mont2a[countM] == 1'b1 && ((monttemp2[0] == 1'b1 && mont2b[0] == 1'b1) || (monttemp2[0] == 1'b0 && mont2b[0] == 1'b0))) begin		//m + b is even
						monttemp2_w = (monttemp2 + mont2b) >> 1;
					end
					else if(mont2a[countM] != 1'b1 && monttemp2[0] == 1'b1) begin
						monttemp2_w = (monttemp2 + n) >> 1;
					end
					else begin
						monttemp2_w = monttemp2 >> 1;
					end
					countM_w = countM + 5'd1;
				end
				else if(countM == 5'd16) begin		//countM == 5'd16, for loop finished
					if(monttemp1 >= n)
						monttemp1_w = monttemp1 - n;
					if(monttemp2 >= n)
						monttemp2_w = monttemp2 - n;
					countM_w = countM + 5'd1;
				end
				else begin		//countM == 5'd17, mont finished
					m_w = monttemp1;
					t_w = monttemp2;
				end
			end

			//if ith bit of d is 0, only need to calculate one mont
			else begin
				if(countM < 5'd16) begin
					if(mont2a[countM] == 1'b1 && ((monttemp2[0] == 1'b1 && mont2b[0] == 1'b0) || (monttemp2[0] == 1'b0 && mont2b[0] == 1'b1))) begin		//m + b is odd
						monttemp2_w = (monttemp2 + mont2b + n) >> 1;
					end
					else if(mont2a[countM] == 1'b1 && ((monttemp2[0] == 1'b1 && mont2b[0] == 1'b1) || (monttemp2[0] == 1'b0 && mont2b[0] == 1'b0))) begin		//m + b is even
						monttemp2_w = (monttemp2 + mont2b) >> 1;
					end
					else if(mont2a[countM] != 1'b1 && monttemp2[0] == 1'b1) begin
						monttemp2_w = (monttemp2 + n) >> 1;
					end
					else begin
						monttemp2_w = monttemp2 >> 1;
					end
					countM_w = countM + 5'd1;
				end
				else if(countM == 5'd16) begin		//countM == 5'd16, for loop finished
					if(monttemp2 >= n)
						monttemp2_w = monttemp2 - n;
					countM_w = countM + 5'd1;
				end
				else begin		//countM == 5'd17, mont finished
					t_w = monttemp2;
				end
			end
		end
		S_CALC: begin
			if(countC < 5'd16) begin
				if(key[countC] == 1'd1) begin
					mont_w      = 1'd1;
					mont1a_w    = m;
					mont1b_w    = t;
					monttemp1_w = 20'd0;
					mont2a_w    = t;
					mont2b_w    = t;
					monttemp2_w = 20'd0;
					countM_w    = 5'd0;
				end
				else begin
					mont_w      = 1'd0;
					mont2a_w    = t;
					mont2b_w    = t;
					monttemp2_w = 20'd0;
					countM_w    = 5'd0;
				end
				countC_w = countC + 5'd1;
			end
			else begin		//countC == 5'd16, finished calculations
				countC_w = 5'd0;
				result_w = m[15:0];
				finish_w = 1'd1;
			end
		end
		default: begin
		end
	endcase
end

always @( posedge clk or negedge rst_n ) begin
	if (~rst_n) begin
		state 	  <= S_IDLE;
		RsaPrep   <= 1'b0;
		countC 	  <= 5'd0;
		countM 	  <= 5'd0;
		countP 	  <= 5'd0;
		mont 	  <= 1'b0;
		m 		  <= 20'd0;
		t 		  <= 20'd0;
		k 		  <= 20'd0;
		mont1a 	  <= 20'd0;
		mont1b 	  <= 20'd0;
		monttemp1 <= 20'd0;
		mont2a 	  <= 20'd0;
		mont2b 	  <= 20'd0;
		monttemp2 <= 20'd0;
		result 	  <= 16'd0;
		finish 	  <= 1'd0;
	end
	else begin
		number 	  <= number_w;
		key 	  <= key_w;
		n 		  <= n_w;
		state 	  <= state_w;
		RsaPrep   <= RsaPrep_w;
		countC 	  <= countC_w;
		countM 	  <= countM_w;
		countP 	  <= countP_w;
		mont 	  <= mont_w;
		m 		  <= m_w;
		t 		  <= t_w;
		k 		  <= k_w;
		mont1a 	  <= mont1a_w;
		mont1b 	  <= mont1b_w;
		monttemp1 <= monttemp1_w;
		mont2a 	  <= mont2a_w;
		mont2b 	  <= mont2b_w;
		monttemp2 <= monttemp2_w;
		result 	  <= result_w;
		finish 	  <= finish_w;
	end
end

endmodule