"""Test UART in loopback mode."""
import cocotb
import os
import itertools
import logging
from cocotbext.axi import (
    AxiStreamBus,
    AxiStreamSource,
    AxiStreamSink,
    AxiStreamFrame,
)
import cocotb_test.simulator
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory


class TestBench:
    """The testbench."""

    def __init__(self, dut):
        """Initialize."""
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        s_clk = int(os.getenv("S_CLK", "10"))

        cocotb.start_soon(Clock(dut.aclk, s_clk, units="ns").start())
        cocotb.start_soon(self.uart_loopback())

        self.source = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "s_axis"),
            dut.aclk,
            dut.aresetn,
            reset_active_level=False,
        )
        self.sink = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "m_axis"),
            dut.aclk,
            dut.aresetn,
            reset_active_level=False,
        )

    async def reset(self):
        """Reset."""
        self.dut.aresetn.setimmediatevalue(1)
        for k in range(10):
            await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 0
        for k in range(10):
            await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        for k in range(10):
            await RisingEdge(self.dut.aclk)

    async def uart_loopback(self):
        """Perform loopback."""
        for _ in itertools.count():
            await RisingEdge(self.dut.aclk)
            self.dut.rx.value = self.dut.tx.value


tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, "hdl"))

TEST_TX_DATA = [
    0xAA,
    0x00,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0xAA,
]


async def run_test(
    dut,
):

    tb = TestBench(dut)

    await tb.reset()
    test_frames = []

    for test_data in TEST_TX_DATA:
        test_frame = AxiStreamFrame(bytes([test_data]))

        test_frames.append(test_frame)
        await tb.source.send(test_frame)

    for test_frame in test_frames:
        rx_frame = await tb.sink.recv()

        assert rx_frame.tdata == test_frame.tdata
        assert not rx_frame.tuser

    assert tb.sink.empty()

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.generate_tests()


def test_axis_uart(request):
    """Test."""
    src_files = [
        "axis_uart_v1_0.v",
        "uart_rx.v",
        "uart_tx.v",
        "uart_fifo.v",
        "uart_prescaler.v",
    ]
    dut = "axis_uart_v1_0"
    toplevel = dut
    verilog_sources = [os.path.join(rtl_dir, fname) for fname in src_files]
    module = os.path.splitext(os.path.basename(__file__))[0]

    parameters = {
        "BAUD_PRESCALER": 10,
        "PARITY": 0,
        "BYTE_SIZE": 8,
        "STOP_BITS": 0,
        "FIFO_DEPTH": 16,
        "FLOW_CONTROL": 0,
        "DYNAMIC_CONFIG": 0,
    }

    sim_build = os.path.join(
        tests_dir,
        "sim_build",
        request.node.name.replace("[", "-").replace("]", ""),
    )

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        # extra_env=extra_env,
    )
