# SPDX-FileCopyrightText: © 2024 Fidel Makatia
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def reset_cpu(dut):
    """Reset the CPU and release cleanly."""
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1


async def wait_for_halt(dut, max_cycles=2000):
    """Wait until the CPU halts, return True if halted."""
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            return True
    return False


@cocotb.test()
async def test_reset_state(dut):
    """Verify output is zero during reset."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)

    assert int(dut.uo_out.value) == 0, "GPIO output should be 0 during reset"


@cocotb.test()
async def test_uio_oe(dut):
    """Verify uio_oe is correctly configured (bit 0 is output)."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)
    await ClockCycles(dut.clk, 2)

    assert int(dut.uio_oe.value) == 0x01, f"Expected uio_oe=0x01, got {int(dut.uio_oe.value):#x}"


@cocotb.test()
async def test_count_to_5(dut):
    """Test the count-to-5 demo program.

    The ROM program counts 1 to 5 on GPIO output, then halts.
    We verify the sequence [1, 2, 3, 4, 5] appears on uo_out.
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    gpio_values = []
    prev_value = 0

    for _ in range(2000):
        await RisingEdge(dut.clk)

        current_value = int(dut.uo_out.value)
        if current_value != prev_value and current_value != 0:
            gpio_values.append(current_value)
            prev_value = current_value

        if len(gpio_values) >= 5:
            break

    assert gpio_values[:5] == [1, 2, 3, 4, 5], \
        f"Expected count sequence [1,2,3,4,5], got {gpio_values[:5]}"


@cocotb.test()
async def test_halts_after_count(dut):
    """Verify the CPU halts after counting to 5."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    halted = await wait_for_halt(dut, max_cycles=2000)
    assert halted, "CPU should halt after the count-to-5 program completes"

    assert (int(dut.uio_out.value) & 0x01) == 1, "Expected halted signal on uio_out[0]"


@cocotb.test()
async def test_final_gpio_value(dut):
    """Verify the final GPIO output is 5 when the CPU halts."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    halted = await wait_for_halt(dut, max_cycles=2000)
    assert halted, "CPU should halt"

    assert int(dut.uo_out.value) == 5, \
        f"Expected final gpio_out=5, got {int(dut.uo_out.value)}"
