`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: mcjtag
// 
// Create Date: 03.10.2019 14:07:08
// Design Name: 
// Module Name: uart_tx
// Project Name: axis_uart
// Target Devices: All
// Tool Versions: 2018.3
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_uart_v1_0 #(
	parameter integer BAUD_PRESCALER = 10, /* Baudrate Prescaler */
	parameter integer PARITY = 0,          /* 0(none), 1(even), 2(odd), 3(mark), 4(space) */
	parameter integer WORD_SIZE = 8,       /* Byte Size (16 max) */
	parameter integer STOP_BITS = 0,       /* 0(one stop), 1(two stops) */
	parameter integer FIFO_DEPTH = 16,     /* FIFO Depth */
	parameter integer FLOW_CONTROL = 0,    /* RTS/CTS */
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
	input wire                           aclk,
	input wire                           aresetn,
	/* AXI-Stream Interface (Slave) */
	input wire [WORD_SIZE-1:0]           s_axis_tdata,
	input wire                           s_axis_tvalid,
	output wire                          s_axis_tready,
	/* AXI-Stream Interface (Master) */
	output wire [WORD_SIZE-1:0]          m_axis_tdata,
	output wire                          m_axis_tuser, /* Parity Error */
	output wire                          m_axis_tvalid,
	input wire                           m_axis_tready,
	// UART Port
	output wire                          tx,
	input wire                           rx,
	output wire                          rts,          /* Active when FLOW_CONTROL == 1 */
	input wire                           cts,           /* Active when FLOW_CONTROL == 1 */


  // AXI MM interface
  input                                S_AXI_ARESETN,
  input [(C_S_AXI_ADDR_WIDTH-1):0]     S_AXI_AWADDR,
  input [2:0]                          S_AXI_AWPROT,
  input                                S_AXI_AWVALID,
  output                               S_AXI_AWREADY,
  input [(C_S_AXI_DATA_WIDTH-1):0]     S_AXI_WDATA,
  input [((C_S_AXI_DATA_WIDTH/8)-1):0] S_AXI_WSTRB,
  input                                S_AXI_WVALID,
  output                               S_AXI_WREADY,
  output [1:0]                         S_AXI_BRESP,
  output                               S_AXI_BVALID,
  input                                S_AXI_BREADY,
  input [(C_S_AXI_ADDR_WIDTH-1):0]     S_AXI_ARADDR,
  input [2:0]                          S_AXI_ARPROT,
  input                                S_AXI_ARVALID,
  output                               S_AXI_ARREADY,
  output [(C_S_AXI_DATA_WIDTH-1):0]    S_AXI_RDATA,
  output [1:0]                         S_AXI_RRESP,
  output                               S_AXI_RVALID,
  input                                S_AXI_RREADY

);

   wire tx_busy, rx_busy;
   wire rx_empty, tx_full;
   wire [2:0] parity_config;
   wire [15:0] prescaler_config;
   wire stopb_config;
   assign rx_empty = (m_axis_tvalid==0);
   assign tx_full = (s_axis_tready==0);

uart_tx #(
	.BAUD_PRESCALER(BAUD_PRESCALER),
	.PARITY(PARITY),
	.WORD_SIZE(WORD_SIZE),
	.STOP_BITS(STOP_BITS),
	.FIFO_DEPTH(FIFO_DEPTH)
) uart_tx_inst
(
 .aclk(aclk),
 .aresetn(aresetn),
 .s_axis_tdata(s_axis_tdata),
 .s_axis_tvalid(s_axis_tvalid),
 .s_axis_tready(s_axis_tready),
 .txd(tx),
 .ctsn(FLOW_CONTROL ? cts : 1'b0),
 .busy(tx_busy),
 .prescaler_config(prescaler_config),
 .parity_config(parity_config),
 .stop_bits_config(stopb_config)
);

uart_rx #(
	.BAUD_PRESCALER(BAUD_PRESCALER),
	.PARITY(PARITY),
	.WORD_SIZE(WORD_SIZE),
	.STOP_BITS(STOP_BITS),
	.FIFO_DEPTH(FIFO_DEPTH)
) uart_rx_inst
(
 .aclk(aclk),
 .aresetn(aresetn),
 .m_axis_tdata(m_axis_tdata),
 .m_axis_tuser(m_axis_tuser),
 .m_axis_tvalid(m_axis_tvalid),
 .m_axis_tready(m_axis_tready),
 .rxd(rx),
 .rtsn(rts),
 .busy(rx_busy),
 .prescaler_config(prescaler_config),
 .parity_config(parity_config),
 .stop_bits_config(stopb_config)
);

uart_axislave
#(
  .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) axislave
(
 .S_AXI_ACLK(aclk),
 .S_AXI_ARESETN(aresetn),
 .S_AXI_AWADDR(S_AXI_AWADDR),
 .S_AXI_AWPROT(S_AXI_AWPROT),
 .S_AXI_AWVALID(S_AXI_AWVALID),
 .S_AXI_AWREADY(S_AXI_AWREADY),
 .S_AXI_WDATA(S_AXI_WDATA),
 .S_AXI_WSTRB(S_AXI_WSTRB),
 .S_AXI_WVALID(S_AXI_WVALID),
 .S_AXI_WREADY(S_AXI_WREADY),
 .S_AXI_BRESP(S_AXI_BRESP),
 .S_AXI_BVALID(S_AXI_BVALID),
 .S_AXI_BREADY(S_AXI_BREADY),
 .S_AXI_ARADDR(S_AXI_ARADDR),
 .S_AXI_ARPROT(S_AXI_ARPROT),
 .S_AXI_ARVALID(S_AXI_ARVALID),
 .S_AXI_ARREADY(S_AXI_ARREADY),
 .S_AXI_RDATA(S_AXI_RDATA),
 .S_AXI_RRESP(S_AXI_RRESP),
 .S_AXI_RVALID(S_AXI_RVALID),
 .S_AXI_RREADY(S_AXI_RREADY),
 .PR_DIV(prescaler_config),
 .STOP_BITS(stopb_config),
 .PARITY(parity_config),
 .RXE(rx_empty),
 .TXF(tx_full),
 .RXB(rx_busy),
 .TXB(tx_busy)
 );

`ifdef COCOTB_SIM
   initial begin
      $dumpfile ("axis_uart_v1_0.vcd");
      $dumpvars (0, axis_uart_v1_0);
      #1;
   end
`endif

endmodule
