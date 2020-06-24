
`default_nettype none
`timescale 1ns/1ps

// twoclock_unfifo: dual-clock FIFO whose (two-word) memory is allowed
// to store only a single word at a given time.  At any given moment
// (modulo clock-domain crossings), the FIFO is either empty or full.
// The purpose is to allow a DIZE-bit-wide word to cross safely from
// the wclk clock domain to the rclk clock domain, but with smaller
// logic/area utilization than the more general "aFifo" dual-clock
// FIFO implementation for which this module is intended to be a
// drop-in replacement.
//
// One exception to the "drop-in replacement" statement is that
// twoclock_unfifo needs only a single reset*, synchrhonous to rclk;
// it then generates its own wclk-synchronous reset*.  If a
// wclk-synchronous reset* signal is already readily available, then
// one could save a bit more logic by adding a "wrst_n_i" input here.
//
// Motivation for this module and relevant discussion of issues are in
// "Clock Domain Crossing (CDC) Design & Verification Techniques Using
// SystemVerilog" paper by Clifford Cummings, SNUG-2008:
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf

module twoclock_unfifo #( parameter DSIZE=16 )
  (
   input  wire             rclk,      // read clock
   input  wire             rrst_n_i,  // synchronous reset* (rclk)
   input  wire             rinc_i,    // read enable (rclk)
   output wire             rempty_o,  // valid* flag for rdata_o (rclk)
   output wire [DSIZE-1:0] rdata_o,   // data out
   input  wire             wclk,      // write clock
   input  wire             winc_i,    // write enable (wclk)
   input  wire [DSIZE-1:0] wdata_i,   // data in
   output wire             wfull_o    // full flag (wclk)
   );
    // Synchronize reset signal into wclk domain
    reg [2:0] wsync_reset;  // paranoid 3-FF synchronizer
    wire wreset = wsync_reset[2];  // synchronizer output
    always @ (posedge wclk) begin
        wsync_reset[2:0] <= {wsync_reset[1:0],!rrst_n_i};
    end
    // This logic mostly follows aFifo.v and the modules instantiated
    // by aFifo.  Note that a one-bit-wide "counter" is already
    // Gray-coded, so the pointer/address logic here is simpler than
    // in aFifo.  First, sync FIFO read pointer into wclk domain.
    reg wptr, rptr, wq1_rptr, wq2_rptr, rq1_wptr, rq2_wptr;
    always @ (posedge wclk) begin
        if (wreset) begin
            wq2_rptr <= 1'b0;
            wq1_rptr <= 1'b0;
        end else begin
            wq2_rptr <= wq1_rptr;
            wq1_rptr <= rptr;
        end
    end
    // Sync FIFO write pointer into rclk domain.
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rq2_wptr <= 1'b0;
            rq1_wptr <= 1'b0;
        end else begin
            rq2_wptr <= rq1_wptr;
            rq1_wptr <= wptr;
        end
    end
    // The FIFO "memory" is just a pair of DSIZE-bit-wide flip-flops
    // and a multiplexer to choose between them.
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
    // Update rptr and rempty: rptr will toggle when a valid read is
    // performed.  The "unfifo" will be empty (next rclk cycle) if the
    // read and write pointers will be equal (next rclk cycle).
    wire rnext = rptr ^ (rinc_i && !rempty_o);
    reg rempty;
    assign rempty_o = rempty;
    always @ (posedge rclk) begin
        if (!rrst_n_i) begin
            rptr <= 1'b0;
            rempty <= 1'b1;
        end else begin
            rptr <= rnext;
            rempty <= (rnext == rq2_wptr);
        end
    end
    // Update wptr and wfull: wptr will toggle when a valid write is
    // performed.  The "unfifo" will be full (next wclk cycle) if the
    // read and write pointers will be unequal (next wclk cycle),
    // i.e. the "unfifo" is full once it is no longer empty, so only
    // one word at a time can be stored.
    wire wnext = wptr ^ (winc_i && !wfull_o);
    reg wfull;
    assign wfull_o = wfull;
    always @ (posedge wclk) begin
        if (wreset) begin
            wptr <= 1'b0;
            wfull <= 1'b0;
        end else begin
            wptr <= wnext;
            wfull <= (wnext != wq2_rptr);  // full if not empty!
        end
    end
endmodule
