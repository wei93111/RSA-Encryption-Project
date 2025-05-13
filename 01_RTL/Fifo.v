module FIFO
#(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 256,
    parameter BIT_SIZE   = $clog2(FIFO_DEPTH)
) (
    input                       clk,
    input                       rst_n,
    input                       wr_en,
    input                       rd_en,
    input      [DATA_WIDTH-1:0] data_wr,
    output reg [DATA_WIDTH-1:0] data_rd,
    output wire                 empty
);

// no implementation of fifo overflow handling (for simplicity, since fifo depth should be enough)

reg [DATA_WIDTH-1:0] memory [FIFO_DEPTH-1:0];

reg [BIT_SIZE:0] wrptr;
reg [BIT_SIZE:0] rdptr;

assign empty = (wrptr == rdptr) ? 1'b1 : 1'b0;    // empty is flagged in real time

// write operation
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        wrptr <= 0;
    end
    else begin
        if(wr_en) begin
            memory[wrptr] <= data_wr;    // data is written in next cycle after wr_en
            wrptr         <= (wrptr == FIFO_DEPTH-1) ? 0 : wrptr + 1;
        end
    end
end

// read operation
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        rdptr <= 0;
    end
    else begin
    if(rd_en && ~empty) begin            // can't read + write when ptrs on same address
            data_rd <= memory[rdptr];    // data is output in next cycle after rd_en
            rdptr   <= (rdptr == FIFO_DEPTH-1) ? 0 : rdptr + 1;
        end
    end
end

endmodule