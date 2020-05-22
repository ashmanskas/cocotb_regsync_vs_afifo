
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles

@cocotb.test()
async def regsync_test1(dut):
    """ put description here """

    dut.wdata <= 0
    dut.rinc <= 0
    dut.winc <= 0
    dut.reset <= 0

    print("datasize =", int(dut.dut2.fifomem.DATASIZE))
    afifo_datasize = int(dut.dut2.fifomem.DATASIZE)
    for i in range(afifo_datasize):
        dut.dut2.fifomem.mem[i] <= 0
    dut.dut3.mem0 <= 0
    dut.dut3.mem1 <= 0
    
    clk40 = Clock(dut.rclk, 25, units="ns")  # 40 MHz rclk
    clk160 = Clock(dut.wclk, 25/4, units="ns")  # 160 MHz wclk
    cocotb.fork(clk40.start())
    cocotb.fork(clk160.start())

    await ClockCycles(dut.rclk, 10)
    await FallingEdge(dut.rclk)
    dut.reset <= 1
    await FallingEdge(dut.rclk)
    dut.reset <= 0
    await ClockCycles(dut.rclk, 10)
    await FallingEdge(dut.rclk)
    assert dut.rempty1 == 1, "expect empty after reset"

    for i in range(10):
        await FallingEdge(dut.wclk)
        dut.winc <= 1
        dut.wdata <= random.randint(0, 65535)
        await FallingEdge(dut.wclk)
        dut.winc <= 0
        #dut.wdata <= 0
        await FallingEdge(dut.wclk)
        for j in range(10):
            await FallingEdge(dut.rclk)
            if dut.rempty1 == 0: break
        await FallingEdge(dut.rclk)
        assert dut.rempty1 == 0, "expect !empty after write"
        dut.rinc <= 1
        await FallingEdge(dut.rclk)
        dut.rinc <= 0
        await FallingEdge(dut.rclk)
        assert dut.rempty1 == 1, "expect empty after read"
        await ClockCycles(dut.rclk, random.randint(5, 15))

    await ClockCycles(dut.rclk, 20)
    
