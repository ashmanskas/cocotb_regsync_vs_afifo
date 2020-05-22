// Next step: try making a version of this that uses Cummings's
// "two-register FIFIO" idea, modelled on Paul's aFifo implementation.

`default_nettype none
`timescale 1ns/1ps

//
// WARNING: This module was developed and tested assuming that the
// wclk frequency is approximately 4x the rclk frequency.  For
// discussion of relevant issues, see "Clock Domain Crossing (CDC)
// Design & Verification Techniques Using SystemVerilog" paper by
// Clifford Cummings, SNUG-2008:
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
//
// The purpose of this module is to synchronize wdata (in the wclk
// domain) into rdata (in the rclk domain) upon receipt of a winc
// pulse.
//
module strobed_reg_sync #( parameter DSIZE=16 )
  (
   input  wire             rclk,      // read clock
   input  wire             rrst_n_i,  // synchronous reset* (rclk)
   input  wire             rinc_i,    // read enable (rclk)
   output reg              rempty_o,  // valid* flag for rdata_o (rclk)
   output reg  [DSIZE-1:0] rdata_o,   // data out
   input  wire             wclk,      // write clock
   input  wire             winc_i,    // write enable (wclk)
   input  wire [DSIZE-1:0] wdata_i,   // data in
   output wire             wfull_o    // full flag (wclk)
   );
    // Below, reset signal will be synchronized into wclk domain.
    wire wreset;
    // Register the write request and the data to be written, which
    // are synchronous to wclk.
    reg winc_ff;
    reg [DSIZE-1:0] wdata_ff;
    always @ (posedge wclk) begin
        if (wreset) begin
            winc_ff <= 0;
            wdata_ff <= 0;
        end else begin
            winc_ff <= winc_i;
            wdata_ff <= wdata_i;
        end
    end
    // If an earlier write has not yet been acknowledged with a rinc
    // pulse, then a new write request is ignored.  Otherwise, stretch
    // out the winc pulse to be at least 1.5x the period of rclk
    // (recommended by Cummings).  In this implementation,
    // winc_stretch should also be wide enough to account for the
    // latency of synchronizing rempty into wsync_empty, so that
    // wsync_empty is deasserted before winc_stretch is deasserted.
    wire wsync_empty;  // see logic below
    assign wfull_o = !wsync_empty;
    reg [3:0] wcount;
    reg winc_stretch;
    reg [DSIZE-1:0] cdc_data;  // data passed across clock-domain crossing
    always @ (posedge wclk) begin
        if (wreset) begin
            wcount <= 0;
            winc_stretch <= 0;
            cdc_data <= 0;
        end else if (winc_ff && wsync_empty && !winc_stretch) begin
            wcount <= 6;
            winc_stretch <= 1;
            cdc_data <= wdata_ff;
        end else if (wcount) begin
            wcount <= wcount-1;
            winc_stretch <= 1;
        end else begin
            winc_stretch <= 0;
        end
    end
    // Synchronize the stretched winc pulse into the rclk domain.
    reg [3:0] rsync_winc_stretch;  // paranoid 3-FF synchro + 1 pipeline
    wire rsync_winc = rsync_winc_stretch[3:2]==2'b01;  // synchronizer output
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rsync_winc_stretch[3:0] <= 0;
        end else begin
            rsync_winc_stretch[3:0] <= {rsync_winc_stretch[2:0],winc_stretch};
        end
    end
    // Process synchronized winc pulse in rclk domain
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rdata_o <= 0;
            rempty_o <= 1;
        end else if (rsync_winc) begin
            rdata_o <= cdc_data;
            rempty_o <= 0;
        end else if (rinc_i && !rempty_o) begin
            rdata_o <= 0;
            rempty_o <= 1;
        end
    end
    // Synchronize reset signal into wclk domain
    reg [2:0] wsync_reset;  // paranoid 3-FF synchronizer
    assign wreset = wsync_reset[2];  // synchronizer output
    always @ (posedge wclk) begin
        wsync_reset[2:0] <= {wsync_reset[1:0],!rrst_n_i};
    end
    // Synchronize rempty_o back into the wclk domain.
    reg [2:0] wsync_rempty;  // paranoid 3-FF synchronizer
    assign wsync_empty = wsync_rempty[2];  // synchronizer output
    always @ (posedge wclk) begin
        if (wreset) begin
            wsync_rempty[2:0] <= 3'b111;
        end else begin
            wsync_rempty[2:0] <= {wsync_rempty[1:0],rempty_o};
        end
    end
endmodule

module twoclock_unfifo #( parameter DSIZE=16 )
  (
   input  wire             rclk,      // read clock
   input  wire             rrst_n_i,  // synchronous reset* (rclk)
   input  wire             rinc_i,    // read enable (rclk)
   output reg              rempty_o,  // valid* flag for rdata_o (rclk)
   output wire [DSIZE-1:0] rdata_o,   // data out
   input  wire             wclk,      // write clock
   input  wire             winc_i,    // write enable (wclk)
   input  wire [DSIZE-1:0] wdata_i,   // data in
   output reg              wfull_o    // full flag (wclk)
   );
    // Synchronize reset signal into wclk domain
    reg [2:0] wsync_reset;  // paranoid 3-FF synchronizer
    wire wreset = wsync_reset[2];  // synchronizer output
    always @ (posedge wclk) begin
        wsync_reset[2:0] <= {wsync_reset[1:0],!rrst_n_i};
    end
    // Mostly follows aFifo.v and modules it instantiates
    reg wptr, rptr, wq1_rptr, wq2_rptr, rq1_wptr, rq2_wptr;
    always @ (posedge wclk) begin
        if (wreset) begin
            wq2_rptr <= 0;
            wq1_rptr <= 0;
        end else begin
            wq2_rptr <= wq1_rptr;
            wq1_rptr <= rptr;
        end
    end
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rq2_wptr <= 0;
            rq1_wptr <= 0;
        end else begin
            rq2_wptr <= rq1_wptr;
            rq1_wptr <= wptr;
        end
    end
    reg [DSIZE-1:0] mem0, mem1;
    assign rdata_o = rptr ? mem1 : mem0;
    always @ (posedge wclk) begin
        if (winc_i && !wfull_o) begin
            if (wptr) begin
                mem1 <= wdata_i;
            end else begin
                mem0 <= wdata_i;
            end
        end
    end
    wire rnext = rptr ^ (rinc_i && !rempty_o);
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rptr <= 0;
            rempty_o <= 1;
        end else begin
            rptr <= rnext;
            rempty_o <= (rnext == rq2_wptr);
        end
    end
    wire wnext = wptr ^ (winc_i && !wfull_o);
    always @ (posedge wclk) begin
        if (wreset) begin
            wptr <= 0;
            wfull_o <= 0;
        end else begin
            wptr <= wnext;
            wfull_o <= (wnext != wq2_rptr);  // full if not empty!
        end
    end
endmodule
