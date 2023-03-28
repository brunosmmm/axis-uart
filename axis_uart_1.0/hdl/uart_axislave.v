`define PRESCALER_DIV_INDEX 0
`define PRESCALER_RESERVED_INDEX 16
`define FORMAT_STOPBITS_INDEX 0
`define FORMAT_PARITY_INDEX 1
`define FORMAT_RESERVED_INDEX 4
`define STATUS_TXBUSY_INDEX 0
`define STATUS_RXBUSY_INDEX 1
`define STATUS_RXEMPTY_INDEX 2
`define STATUS_TXFULL_INDEX 3
`define STATUS_RESERVED_INDEX 4
module uart_axislave
#(
parameter integer C_S_AXI_DATA_WIDTH = 32,
parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
input  S_AXI_ACLK,
input  S_AXI_ARESETN,
input [(C_S_AXI_ADDR_WIDTH-1):0] S_AXI_AWADDR,
input [2:0] S_AXI_AWPROT,
input  S_AXI_AWVALID,
output  S_AXI_AWREADY,
input [(C_S_AXI_DATA_WIDTH-1):0] S_AXI_WDATA,
input [((C_S_AXI_DATA_WIDTH/8)-1):0] S_AXI_WSTRB,
input  S_AXI_WVALID,
output  S_AXI_WREADY,
output [1:0] S_AXI_BRESP,
output  S_AXI_BVALID,
input  S_AXI_BREADY,
input [(C_S_AXI_ADDR_WIDTH-1):0] S_AXI_ARADDR,
input [2:0] S_AXI_ARPROT,
input  S_AXI_ARVALID,
output  S_AXI_ARREADY,
output [(C_S_AXI_DATA_WIDTH-1):0] S_AXI_RDATA,
output [1:0] S_AXI_RRESP,
output  S_AXI_RVALID,
input  S_AXI_RREADY,
output [15:0] PR_DIV,
output  STOP_BITS,
output [2:0] PARITY,
input  RXE,
input  TXF,
input  RXB,
input  TXB
);
    reg [(C_S_AXI_ADDR_WIDTH-1):0] axi_awaddr;
    reg  axi_awready;
    reg  axi_wready;
    reg [1:0] axi_bresp;
    reg  axi_bvalid;
    reg [(C_S_AXI_ADDR_WIDTH-1):0] axi_araddr;
    reg  axi_arready;
    reg [(C_S_AXI_DATA_WIDTH-1):0] axi_rdata;
    reg [1:0] axi_rresp;
    reg  axi_rvalid;
    localparam  ADDR_LSB = ((C_S_AXI_DATA_WIDTH/32)+1);
    localparam  OPT_MEM_ADDR_BITS = 3'b011;
    //Register Space
    reg [31:0] REG_STATUS;
    localparam [31:0] WRMASK_STATUS = 32'h00000000;
    reg [31:0] REG_FORMAT;
    localparam [31:0] WRMASK_FORMAT = 32'h0000000F;
    reg [31:0] REG_PRESCALER;
    localparam [31:0] WRMASK_PRESCALER = 32'h0000FFFF;
    wire  slv_reg_rden;
    wire  slv_reg_wren;
    reg [(C_S_AXI_DATA_WIDTH-1):0] reg_data_out;
    integer  byte_index;
    //I/O Connection assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;
    //User logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_awready <= 1'h0;
        end
        else begin
            if (((~axi_awready&&S_AXI_AWVALID)&&S_AXI_WVALID)) begin
                axi_awready <= 1'h1;
            end
            else begin
                axi_awready <= 1'h0;
            end
        end
    end
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_awaddr <= 1'h0;
        end
        else begin
            if (((~axi_awready&&S_AXI_AWVALID)&&S_AXI_WVALID)) begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_wready <= 1'h0;
        end
        else begin
            if (((~axi_awready&&S_AXI_AWVALID)&&S_AXI_WVALID)) begin
                axi_wready <= 1'h1;
            end
            else begin
                axi_wready <= 1'h0;
            end
        end
    end
    
    //generate slave write enable
    assign slv_reg_wren = (((axi_wready&&S_AXI_WVALID)&&axi_awready)&&S_AXI_AWVALID);
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            //Reset Registers
            REG_STATUS <= 32'h00000000;
            REG_FORMAT <= 32'h00000000;
            REG_PRESCALER <= 32'h00000019;
        end
        else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[((ADDR_LSB+OPT_MEM_ADDR_BITS)-1):ADDR_LSB])
                default: begin
                    REG_PRESCALER <= REG_PRESCALER;
                    REG_FORMAT <= REG_FORMAT;
                    REG_STATUS <= REG_STATUS;
                end
                3'h0: begin
                    for (byte_index = 0; byte_index <= 3; byte_index = (byte_index+1)) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            REG_PRESCALER[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                        end
                    end
                    
                end
                3'h1: begin
                    for (byte_index = 0; byte_index <= 3; byte_index = (byte_index+1)) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            REG_FORMAT[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                        end
                    end
                    
                end
                3'h2: begin
                    for (byte_index = 0; byte_index <= 3; byte_index = (byte_index+1)) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            REG_STATUS[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                        end
                    end
                    
                end
                
                endcase
                
            end
        end
    end
    
    //Write response logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_bvalid <= 1'h0;
            axi_bresp <= 1'h0;
        end
        else begin
            if (((((axi_awready&&S_AXI_AWVALID)&&~axi_bvalid)&&axi_wready)&&S_AXI_WVALID)) begin
                axi_bvalid <= 1'h1;
                axi_bresp <= 1'h0;
            end
            else begin
                if ((S_AXI_BREADY&&axi_bvalid)) begin
                    axi_bvalid <= 1'h0;
                end
            end
        end
    end
    
    //axi_arready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_arready <= 1'h0;
            axi_araddr <= 1'h0;
        end
        else begin
            if ((~axi_arready&&S_AXI_ARVALID)) begin
                axi_arready <= 1'h1;
                axi_araddr <= S_AXI_ARADDR;
            end
            else begin
                axi_arready <= 1'h0;
            end
        end
    end
    
    //arvalid generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_rvalid <= 1'h0;
            axi_rresp <= 1'h0;
        end
        else begin
            if (((axi_arready&&S_AXI_ARVALID)&&~axi_rvalid)) begin
                axi_rvalid <= 1'h1;
                axi_rresp <= 1'h0;
            end
            else begin
                if ((axi_rvalid&&S_AXI_RREADY)) begin
                    axi_rvalid <= 1'h0;
                end
            end
        end
    end
    
    //Register select and read logic
    assign slv_reg_rden = ((axi_arready&S_AXI_ARVALID)&~axi_rvalid);
    always @(*) begin
        if (S_AXI_ARESETN == 0) begin
            reg_data_out <= 1'h0;
        end
        else begin
            case (axi_araddr[((ADDR_LSB+OPT_MEM_ADDR_BITS)-1):ADDR_LSB])
            default: begin
                reg_data_out <= 1'h0;
            end
            3'h0: begin
                reg_data_out <= {16'b0000000000000000, REG_PRESCALER[15:0]};
            end
            3'h1: begin
                reg_data_out <= {28'b0000000000000000000000000000, REG_FORMAT[3:1], REG_FORMAT[0]};
            end
            3'h2: begin
                reg_data_out <= {28'b0000000000000000000000000000, TXF, RXE, RXB, TXB};
            end
            
            endcase
            
        end
    end
    
    //data output
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_rdata <= 1'h0;
        end
        else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end
        end
    end
    
    //Output assignment
    assign PARITY = REG_FORMAT[3:1];
    assign STOP_BITS = REG_FORMAT[0];
    assign PR_DIV = REG_PRESCALER[15:0];
endmodule
