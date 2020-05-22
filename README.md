# cocotb_regsync_vs_afifo

I tried two different approaches to Paul's request to replace with
something smaller/simpler the two aFifo instances in
`hcc_InputChannel.v`.  The first approach is the module named
`strobed_reg_sync`. The second approach is the module named
`twoclock_unfifo`.  Both are in the file `strobed_reg_sync.v`. Both
are inspired by Clifford Cummings's SNUG-2008 [paper][1], "Clock
Domain Crossing (CDC) Design & Verification Techniques using
SystemVerilog."

The first approach stretches out the write-enable pulse so that it is
a little more than 1.5x the period of rclk, so that it can then be
safely synchronized into the rclk domain. As the stretched pulse
crosses the clock-domain boundary, the data cross with it. Since
successive write-enable pulses are widely separated, a stable copy of
the data can be latched into the rclk domain.

Three things motivated me to try the second approach. First, I was
annoyed that `strobed_reg_sync` responded so much more slowly than
Paul's `aFifo`, in spite of its solving an easier problem. Second,
Cummings explicitly suggests a "two-memory-location FIFO" as a
solution to the problem at hand. Third, I think Paul may find it
appealing to replace `aFifo`, in this context, with a highly
simplified version of essentially the same idea, in the form of the
"unfifo." The "unfifo" solution seems closer to a known known.

In the screen capture files, the suffix "1" corresponds to the outputs
of `strobed_reg_sync` (first approach); the suffix "2" corresponds to
the outputs of Paul's `aFifo` module; and the suffix "3" corresponds
to the outputs of `twoclock_unfifo` (second approach).

I am sharing this with Ben and Adrian because I thought they might
appreciate my having used this coding exercise as an excuse to try out
two things: (1) using the developmental [Cocotb 1.4][2] which uses the
relatively new Python3 "async def" and "await" keywords and seems
generally to allow for simpler-looking Cocotb code; and (2) using
[Icarus Verilog][3] running on my MacBook Air to run the Cocotb
simulation, instead of logging into my campus Linux box to run the
fancy commercial simulator. Actually, another intriguing feature of
Cocotb 1.4 that I have been meaning to try (but have not yet) is the
ability to force/release signals in addition to depositing values into
registers; I have been wondering whether this feature would allow me
to embed module-specific unit tests into a test suite that runs on the
full design, e.g. by overriding the inputs to a given instance of that
module.

[1]: http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
[2]: https://docs.cocotb.org/en/latest/release_notes.html#cocotb-1-4-0-dev0-2020-05-22
[3]: http://iverilog.icarus.com/
