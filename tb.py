
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles

async def write_then_read(dut,
                          try_write_twice=False):
    """ordinary write-then-read operation"""
    await FallingEdge(dut.wclk)
    dut.winc <= 1
    wordvalue = random.randint(0, 65535)
    dut.wdata <= wordvalue
    await FallingEdge(dut.wclk)
    if try_write_twice:
        await FallingEdge(dut.wclk)
    dut.winc <= 0
    await FallingEdge(dut.wclk)
    for j in range(10):
        await FallingEdge(dut.rclk)
        if dut.rempty == 0: break
    await FallingEdge(dut.rclk)
    assert dut.rempty == 0, "expect UNFIFO !empty after write"
    assert dut.rdata == wordvalue, "expect to read back written word"
    dut.rinc <= 1
    await FallingEdge(dut.rclk)
    dut.rinc <= 0
    await FallingEdge(dut.rclk)
    assert dut.rempty == 1, "expect UNFIFO empty after read"
    if try_write_twice:
        # complication: AFIFO actually stores the second word!
        dut.rinc <= 1
        await FallingEdge(dut.rclk)
        dut.rinc <= 0
        await FallingEdge(dut.rclk)
    assert dut.rempty == 1, "expect UNFIFO empty after read"
    #import pdb; pdb.set_trace()
    await ClockCycles(dut.rclk, random.randint(1, 5))

@cocotb.test()
async def regsync_test1(dut):
    """ put description here """

    dut.wdata <= 0
    dut.rinc <= 0
    dut.winc <= 0
    dut.reset <= 0

    dut.dut.mem0 <= 0
    dut.dut.mem1 <= 0
    
    clk40 = Clock(dut.rclk, 25, units="ns")  # 40 MHz rclk
    clk160 = Clock(dut.wclk, 25/4, units="ns")  # 160 MHz wclk
    cocotb.fork(clk40.start())
    cocotb.fork(clk160.start())

    # Reset FIFO
    await ClockCycles(dut.rclk, 10)
    await FallingEdge(dut.rclk)
    dut.reset <= 1
    await FallingEdge(dut.rclk)
    dut.reset <= 0
    await ClockCycles(dut.rclk, 10)
    await FallingEdge(dut.rclk)
    assert dut.rempty == 1, "expect UNFIFO empty after reset"

    # Try a sequence of ordinary write-then-read operations
    for i in range(10):
        await write_then_read(dut)

    # Try reading when empty
    await ClockCycles(dut.rclk, 10)
    await FallingEdge(dut.rclk)
    dut.rinc <= 1
    await FallingEdge(dut.rclk)
    dut.rinc <= 0
    await FallingEdge(dut.rclk)
    assert dut.rempty == 1, "expect UNFIFO still emtpy"
    await ClockCycles(dut.rclk, 10)

    # Try writing twice
    for i in range(3):
        await write_then_read(dut, try_write_twice=True)

    await ClockCycles(dut.rclk, 20)
    
