`default_nettype none
`timescale 1ns/1ps

module tb;

    reg reset=0, rclk=0, rinc=0, wclk=0, winc=0;
    wire rempty, wfull;
    localparam W=16;
    wire [W-1:0] rdata;
    reg [W-1:0] wdata;

    twoclock_unfifo #(.DSIZE(W))
    dut (.rclk(rclk), 
         .rrst_n_i(!reset),
         .rinc_i(rinc),
         .rempty_o(rempty),
         .rdata_o(rdata),
         .wclk(wclk),
         .winc_i(winc),
         .wdata_i(wdata),
         .wfull_o(wfull));

    initial begin
        $dumpfile("tb.lxt");
        $dumpvars(0, tb);
    end

endmodule
