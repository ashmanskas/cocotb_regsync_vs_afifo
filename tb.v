`default_nettype none
`timescale 1ns/1ps

module tb;

    reg reset=0, rclk=0, rinc=0, wclk=0, winc=0;
    wire rempty1, rempty2, rempty3, wfull1, wfull2, wfull3;
    localparam W=16;
    wire [W-1:0] rdata1, rdata2, rdata3;
    reg [W-1:0] wdata;

    strobed_reg_sync #(.DSIZE(W))
    dut1 (.rclk(rclk), 
          .rrst_n_i(!reset),
          .rinc_i(rinc),
          .rempty_o(rempty1),
          .rdata_o(rdata1),
          .wclk(wclk),
          .winc_i(winc),
          .wdata_i(wdata),
          .wfull_o(wfull1));

    aFifo #(.DSIZE(W))
    dut2( .rdata(rdata2),
          .walmostfull(wfull2),
          .rempty(rempty2),
          .wdata(wdata),
          .winc(winc),
          .wclk(wclk),
          .wrst_n(!reset),
          .rinc(rinc),
          .rclk(rclk),
          .rrst_n(!reset));

    twoclock_unfifo #(.DSIZE(W))
    dut3 (.rclk(rclk), 
          .rrst_n_i(!reset),
          .rinc_i(rinc),
          .rempty_o(rempty3),
          .rdata_o(rdata3),
          .wclk(wclk),
          .winc_i(winc),
          .wdata_i(wdata),
          .wfull_o(wfull3));

    initial begin
        $dumpfile("tb.lxt");
        $dumpvars(0, tb);
    end

endmodule
