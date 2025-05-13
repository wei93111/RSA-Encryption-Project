`timescale 1ns/1ps
`default_nettype none

`define CLK_PERIOD 2.0
`define MAX_CYCLE 100000
`define IN_DELAY 0.50
`define OUT_DELAY 0.50

`ifdef APR
    `define SDFFILE "../04_APR/output/RSA_APR.sdf"
`endif

`ifdef pat0
    `define TEST_DATA_CNT 35
    `define Mi_file "../00_TESTBENCH/pattern/Mi_pattern0.dat"
    `define Mo_file "../00_TESTBENCH/pattern/Mo_pattern0.dat"
`elsif pat1
    `define TEST_DATA_CNT 52
    `define Mi_file "../00_TESTBENCH/pattern/Mi_pattern1.dat"
    `define Mo_file "../00_TESTBENCH/pattern/Mo_pattern1.dat"
`elsif pat2
    `define TEST_DATA_CNT 46
    `define Mi_file "../00_TESTBENCH/pattern/Mi_pattern2.dat"
    `define Mo_file "../00_TESTBENCH/pattern/Mo_pattern2.dat"
`elsif pat3
    `define TEST_DATA_CNT 37
    `define Mi_file "../00_TESTBENCH/pattern/Mi_pattern3.dat"
    `define Mo_file "../00_TESTBENCH/pattern/Mo_pattern3.dat"
`elsif pat4
    `define TEST_DATA_CNT 46
    `define Mi_file "../00_TESTBENCH/pattern/Mi_pattern4.dat"
    `define Mo_file "../00_TESTBENCH/pattern/Mo_pattern4.dat"
`endif

module tb_RSA;
reg     clk = 0;
reg     rst_n = 1;
reg     i_valid = 0;
reg     [7:0] k;
reg     [15:0] N, Mi;
wire    ack, o_valid;
wire    [15:0] Mo;

reg     clk_start = 0;
reg     change_send_cnt;
integer send_cnt = 0, recv_cnt = 0, error_cnt = 0;

reg     [7:0] k_data[0:`TEST_DATA_CNT-1];
reg     [15:0] N_data[0:`TEST_DATA_CNT-1], Mi_data[0:`TEST_DATA_CNT-1];
reg     [15:0] Mo_data[0:`TEST_DATA_CNT-1];

`ifdef SDF
    initial $sdf_annotate(`SDFFILE, dut);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

initial begin
    $readmemh(`Mi_file, Mi_data);
    $readmemh(`Mo_file, Mo_data);
end

RSA dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_valid    (i_valid),
    .ack        (ack),
    .Mi         (Mi),
    .o_valid    (o_valid),
    .Mo         (Mo)
);

always @(posedge clk) begin
    #(`IN_DELAY);
    if (send_cnt < `TEST_DATA_CNT) i_valid = ($random % 2);
    else i_valid = 0;
end

always @(posedge clk) begin
    #(`CLK_PERIOD - `OUT_DELAY);
    change_send_cnt = i_valid & ack;
end

always #(`CLK_PERIOD/2) begin
    if (clk_start) clk = ~clk;
end

always @(*) begin
    if (i_valid) begin
        k = k_data[send_cnt];
        N = N_data[send_cnt];
        Mi = Mi_data[send_cnt];
    end else begin
        k = 8'hxx;
        N = 8'hxx;
        Mi = 8'hxx;
    end
end

initial begin
    #(`IN_DELAY);
    rst_n = 0;
    #(`CLK_PERIOD * 5.0);
    rst_n = 1;
    #(`CLK_PERIOD * 5.0);
    clk_start = 1;
    
    // SEND INPUT
    @(posedge clk);
    #(`IN_DELAY);
    while (send_cnt < `TEST_DATA_CNT) begin
        if (change_send_cnt) begin
            send_cnt = send_cnt + 1;
            #(`CLK_PERIOD);
        end else begin
            #(`CLK_PERIOD);
        end
    end
end

// CHECK RESULT
initial begin
    @(posedge clk);
    #(`CLK_PERIOD - `OUT_DELAY);
    while (recv_cnt < 5) begin
        if (o_valid) begin
            if (Mo !== Mo_data[recv_cnt]) begin
                $display("Data %0d error, your value: %0h, golden value: %0h", recv_cnt, Mo, Mo_data[recv_cnt]);
                error_cnt = error_cnt + 1;
            end
            recv_cnt = recv_cnt + 1;
        end
        #(`CLK_PERIOD * 1.0);
    end
    if (error_cnt == 0) begin
        $display("==============================================");
        $display("                     Pass                     ");
        $display("==============================================");
    end else begin
        $display("===============================================");
        $display("              There are %0d errors", error_cnt);
        $display("===============================================");
    end
    $finish;
end

// DUMP WAVEFORM
initial begin
    $fsdbDumpfile("tb_RSA.fsdb");
    $fsdbDumpvars(0, tb_RSA, "+mda");
    #(`CLK_PERIOD * `MAX_CYCLE);
    $display("===========================================");
    $display("              Error overtime!");
    $display("===========================================");
    $finish;
end

endmodule
`default_nettype wire