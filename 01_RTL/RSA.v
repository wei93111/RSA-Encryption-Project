module RSA (
    input           clk,
    input           rst_n,
    input           i_valid,
    output          ack,
    input   [15:0]  Mi,
    output          o_valid,
    output  [15:0]  Mo
);

localparam RESET  = 6'b000001;
localparam SET    = 6'b000010;
localparam ADD    = 6'b000100;
localparam SUB    = 6'b001000;
localparam SETKEY = 6'b010000;
localparam OUTPUT = 6'b100000;

reg signed [11:0] stored, stored_w;
reg		   [15:0] ke,     ke_w;
wire 	   [15:0] kd;
wire	   [15:0] n;

assign kd = 16'd11;
assign n  = 16'd52961;

// interface fifo
reg 	    wren,   wren_w;
reg 	    rden,   rden_w;
reg	 [15:0] datawr, datawr_w;
wire [15:0] datard;
wire	    empty;

// control and interface rsa cores
reg		    start_decrypt, start_decrypt_w;
reg		    start_encrypt, start_encrypt_w;
wire		decrypt_busy;
wire		encrypt_busy;
wire [15:0] decrypted;
wire		finish_decrypt;

reg 	    start_exec,   start_exec_w;
reg [15:0]  instruction,  instruction_w;
reg		    set,          set_w;
reg [15:0]  final_result, final_result_w;

assign ack = i_valid;

// stores the encoded instructions
FIFO #(
	.DATA_WIDTH (16),
	.FIFO_DEPTH	(256)
) encodedFIFO(
	.clk		(clk),
	.rst_n		(rst_n),
	.wr_en		(wren),
	.rd_en		(rden),
	.data_wr	(datawr),
	.data_rd	(datard),
	.empty		(empty)
);

// used for decryption of input
RsaCore decryptRSA(
	.clk		(clk),
	.rst_n	    (rst_n),
	.i_start	(start_decrypt),
	.i_number	(datard),
	.i_key		(kd),         
	.i_n		(n),
	.o_result	(decrypted),
	.o_finished	(finish_decrypt),
	.o_busy		(decrypt_busy)
);

// used for encryption of output (can compute in parellel to decrypt module)
RsaCore encryptRSA(
	.clk		(clk),
	.rst_n	    (rst_n),
	.i_start	(start_encrypt),
	.i_number	(final_result),
	.i_key		(ke),
	.i_n		(n),
	.o_result	(Mo),
	.o_finished	(o_valid),
	.o_busy		(encrypt_busy)
);

// Control data flow
always @ (*) begin
	wren_w      	= 1'b0;
	rden_w      	= 1'b0;
	datawr_w        = datawr;
	start_decrypt_w = 1'b0;
	start_exec_w	= 1'b0;
	instruction_w   = instruction;

	// write to encoded fifo
	if(i_valid) begin
		wren_w   = 1'b1;
		datawr_w = Mi;
	end

	// read from encoded fifo and start decryption
	if(~empty && ~decrypt_busy && ~start_decrypt && ~rden) begin
		rden_w 	    = 1'b1;
	end
	if(rden) begin
		start_decrypt_w = 1'b1;
	end

	// execute the decoded instructions
	if(finish_decrypt) begin
		instruction_w = decrypted;
		start_exec_w  = 1'b1;
	end
end

// Execute instructions
always @ (*) begin
	stored_w 		= stored;
	set_w    		= set;
	ke_w	        = ke;
	start_encrypt_w = 1'b0;
	final_result_w  = final_result;

	if(start_exec) begin
		if(~set) begin
			case(instruction[15:10])
				RESET: begin
					stored_w = 0;
				end
				SET: begin
					set_w = 1'b1;
				end
				ADD: begin
					if(stored == 12'd2047) begin
						stored_w = 12'd2047;
					end
					else if(~stored[11] && {2'd0, stored} + {4'd0, instruction[9:0]} > 14'd2047) begin
						stored_w = 12'd2047;
					end
					else begin
						stored_w = stored + $signed({2'd0, instruction[9:0]});
					end
				end
				SUB: begin
					if(stored == -12'd2048) begin
						stored_w = -12'd2048;
					end
					else if(stored[11] && {3'd0, (~(stored[10:0]) + 11'd1)} + {4'd0, instruction[9:0]} > 14'd2048) begin
						stored_w = -12'd2048;
					end
					else begin
						stored_w = stored - $signed({2'd0, instruction[9:0]});
					end
				end
				SETKEY: begin
					ke_w[7:0] = instruction[7:0];
				end
				OUTPUT: begin
					start_encrypt_w = 1'b1;
					final_result_w  = {4'd0, stored};
				end
				default: begin
				end
			endcase
		end
		else begin
			stored_w = instruction[11:0];
			set_w	 = 1'b0;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		stored   	  <= 12'd0;
		ke			  <= 16'd0;
		wren       	  <= 1'b0;
		rden   	      <= 1'b0; 
		datawr 	      <= 16'd0;
		start_decrypt <= 1'b0;
		start_encrypt <= 1'b0;
		start_exec    <= 1'b0;
		instruction	  <= 16'd0;
		set			  <= 1'b0;
		final_result  <= 16'd0;
	end
	else begin
		stored        <= stored_w;
		ke			  <= ke_w;
		wren          <= wren_w;
		rden          <= rden_w;
		datawr        <= datawr_w;
		start_decrypt <= start_decrypt_w;
		start_encrypt <= start_encrypt_w;
		start_exec	  <= start_exec_w;
		instruction   <= instruction_w;
		set			  <= set_w;
		final_result  <= final_result_w;
	end
end

endmodule
