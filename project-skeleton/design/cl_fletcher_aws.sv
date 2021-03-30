// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.


`define FLETCHER_TOP AxiTop
`define DDR_A_ABSENT True
`define DDR_B_ABSENT True
`define DDR_D_ABSENT True

module cl_fletcher_aws #() 

(
   `include "cl_ports.vh"

);

`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_fletcher_aws_defines.vh"

// TIE OFF ALL UNUSED INTERFACES
// Including all the unused interface to tie off
// This list is put in the top of the fie to remind
// developers to remve the specific interfaces
// that the CL will use

`include "unused_flr_template.inc"
`include "unused_pcim_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_ocl_template.inc"


//---------------------------- 
// Internal signals
//---------------------------- 
axi_bus_t lcl_cl_sh_ddra();
axi_bus_t lcl_cl_sh_ddrb();
axi_bus_t lcl_cl_sh_ddrd();
axi_bus_t axi_bus_tied();

axi_bus_t sh_cl_dma_pcis_bus();
axi_bus_t sh_cl_dma_pcis_q();

axi_bus_t sh_bar1_bus();
axi_bus_t cl_axi_slv_bus();
axi_bus_t cl_axi_mstr_bus();

axi_bus_t cl_sh_ddr_bus();

logic clk;
(* dont_touch = "true" *) logic pipe_rst_n;
logic pre_sync_rst_n;
(* dont_touch = "true" *) logic sync_rst_n;
logic sh_cl_flr_assert_q;

logic [3:0] all_ddr_is_ready;
logic [2:0] lcl_sh_cl_ddr_is_ready;

logic dbg_scrb_en;
logic [2:0] dbg_scrb_mem_sel;

//---------------------------- 
// End Internal signals
//----------------------------

// Unused 'full' signals
assign cl_sh_dma_rd_full  = 1'b0;
assign cl_sh_dma_wr_full  = 1'b0;

// Unused *burst signals
assign cl_sh_ddr_arburst[1:0] = 2'h0;
assign cl_sh_ddr_awburst[1:0] = 2'h0;


assign clk = clk_main_a0;

assign cl_sh_id0 = `CL_SH_ID0;
assign cl_sh_id1 = `CL_SH_ID1;

//reset synchronizer
lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_main_n), .out_bus(pipe_rst_n));
   
always_ff @(negedge pipe_rst_n or posedge clk)
   if (!pipe_rst_n)
   begin
      pre_sync_rst_n <= 0;
      sync_rst_n <= 0;
   end
   else
   begin
      pre_sync_rst_n <= 1;
      sync_rst_n <= pre_sync_rst_n;
   end

// The functionality for these signals is TBD so they can can be tied-off.
assign cl_sh_status0 = 32'h0;
assign cl_sh_status1 = 32'h0;

logic sh_cl_ddr_is_ready_q;
always_ff @(posedge clk or negedge sync_rst_n)
  if (!sync_rst_n)
  begin
    sh_cl_ddr_is_ready_q <= 1'b0;
  end
  else
  begin
    sh_cl_ddr_is_ready_q <= sh_cl_ddr_is_ready;
  end  

assign all_ddr_is_ready = {lcl_sh_cl_ddr_is_ready[2], sh_cl_ddr_is_ready_q, lcl_sh_cl_ddr_is_ready[1:0]};


///////////////////////////////////////////////////////////////////////
///////////////// DMA PCIS SLAVE module ///////////////////////////////
///////////////////////////////////////////////////////////////////////
 
assign sh_cl_dma_pcis_bus.awvalid = sh_cl_dma_pcis_awvalid;
assign sh_cl_dma_pcis_bus.awaddr = sh_cl_dma_pcis_awaddr;
assign sh_cl_dma_pcis_bus.awid[5:0] = sh_cl_dma_pcis_awid;
assign sh_cl_dma_pcis_bus.awlen = sh_cl_dma_pcis_awlen;
assign sh_cl_dma_pcis_bus.awsize = sh_cl_dma_pcis_awsize;
assign cl_sh_dma_pcis_awready = sh_cl_dma_pcis_bus.awready;
assign sh_cl_dma_pcis_bus.wvalid = sh_cl_dma_pcis_wvalid;
assign sh_cl_dma_pcis_bus.wdata = sh_cl_dma_pcis_wdata;
assign sh_cl_dma_pcis_bus.wstrb = sh_cl_dma_pcis_wstrb;
assign sh_cl_dma_pcis_bus.wlast = sh_cl_dma_pcis_wlast;
assign cl_sh_dma_pcis_wready = sh_cl_dma_pcis_bus.wready;
assign cl_sh_dma_pcis_bvalid = sh_cl_dma_pcis_bus.bvalid;
assign cl_sh_dma_pcis_bresp = sh_cl_dma_pcis_bus.bresp;
assign sh_cl_dma_pcis_bus.bready = sh_cl_dma_pcis_bready;
assign cl_sh_dma_pcis_bid = sh_cl_dma_pcis_bus.bid[5:0];
assign sh_cl_dma_pcis_bus.arvalid = sh_cl_dma_pcis_arvalid;
assign sh_cl_dma_pcis_bus.araddr = sh_cl_dma_pcis_araddr;
assign sh_cl_dma_pcis_bus.arid[5:0] = sh_cl_dma_pcis_arid;
assign sh_cl_dma_pcis_bus.arlen = sh_cl_dma_pcis_arlen;
assign sh_cl_dma_pcis_bus.arsize = sh_cl_dma_pcis_arsize;
assign cl_sh_dma_pcis_arready = sh_cl_dma_pcis_bus.arready;
assign cl_sh_dma_pcis_rvalid = sh_cl_dma_pcis_bus.rvalid;
assign cl_sh_dma_pcis_rid = sh_cl_dma_pcis_bus.rid[5:0];
assign cl_sh_dma_pcis_rlast = sh_cl_dma_pcis_bus.rlast;
assign cl_sh_dma_pcis_rresp = sh_cl_dma_pcis_bus.rresp;
assign cl_sh_dma_pcis_rdata = sh_cl_dma_pcis_bus.rdata;
assign sh_cl_dma_pcis_bus.rready = sh_cl_dma_pcis_rready;

assign cl_sh_ddr_awid = cl_sh_ddr_bus.awid;
assign cl_sh_ddr_awaddr = cl_sh_ddr_bus.awaddr;
assign cl_sh_ddr_awlen = cl_sh_ddr_bus.awlen;
assign cl_sh_ddr_awsize = cl_sh_ddr_bus.awsize;
assign cl_sh_ddr_awvalid = cl_sh_ddr_bus.awvalid;
assign cl_sh_ddr_bus.awready = sh_cl_ddr_awready;
assign cl_sh_ddr_wid = 16'b0;
assign cl_sh_ddr_wdata = cl_sh_ddr_bus.wdata;
assign cl_sh_ddr_wstrb = cl_sh_ddr_bus.wstrb;
assign cl_sh_ddr_wlast = cl_sh_ddr_bus.wlast;
assign cl_sh_ddr_wvalid = cl_sh_ddr_bus.wvalid;
assign cl_sh_ddr_bus.wready = sh_cl_ddr_wready;
assign cl_sh_ddr_bus.bid = sh_cl_ddr_bid;
assign cl_sh_ddr_bus.bresp = sh_cl_ddr_bresp;
assign cl_sh_ddr_bus.bvalid = sh_cl_ddr_bvalid;
assign cl_sh_ddr_bready = cl_sh_ddr_bus.bready;
assign cl_sh_ddr_arid = cl_sh_ddr_bus.arid;
assign cl_sh_ddr_araddr = cl_sh_ddr_bus.araddr;
assign cl_sh_ddr_arlen = cl_sh_ddr_bus.arlen;
assign cl_sh_ddr_arsize = cl_sh_ddr_bus.arsize;
assign cl_sh_ddr_arvalid = cl_sh_ddr_bus.arvalid;
assign cl_sh_ddr_bus.arready = sh_cl_ddr_arready;
assign cl_sh_ddr_bus.rid = sh_cl_ddr_rid;
assign cl_sh_ddr_bus.rresp = sh_cl_ddr_rresp;
assign cl_sh_ddr_bus.rvalid = sh_cl_ddr_rvalid;
assign cl_sh_ddr_bus.rdata = sh_cl_ddr_rdata;
assign cl_sh_ddr_bus.rlast = sh_cl_ddr_rlast;
assign cl_sh_ddr_rready = cl_sh_ddr_bus.rready;

(* dont_touch = "true" *) logic dma_pcis_slv_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) DMA_PCIS_SLV_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(dma_pcis_slv_sync_rst_n));
cl_dma_pcis_slv #() CL_DMA_PCIS_SLV (
    .aclk(clk),
    .aresetn(dma_pcis_slv_sync_rst_n),

    .sh_cl_dma_pcis_bus(sh_cl_dma_pcis_bus),
    .cl_axi_mstr_bus(cl_axi_mstr_bus),

    .lcl_cl_sh_ddra(lcl_cl_sh_ddra),
    .lcl_cl_sh_ddrb(lcl_cl_sh_ddrb),
    .lcl_cl_sh_ddrd(lcl_cl_sh_ddrd),

    .sh_cl_dma_pcis_q(sh_cl_dma_pcis_q),

    .cl_sh_ddr_bus     (cl_sh_ddr_bus)
  );

///////////////////////////////////////////////////////////////////////
///////////////// DMA PCIS SLAVE module ///////////////////////////////
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
///////////////// Secondary AXI Master module /////////////////////////
///////////////////////////////////////////////////////////////////////

//-----------------------------------------
// BAR 1 Connections -> sh_bar1
//-----------------------------------------
assign bar1_sh_awready = sh_bar1_bus.awready;
assign sh_bar1_bus.awvalid = sh_bar1_awvalid;
assign sh_bar1_bus.awaddr  = sh_bar1_awaddr ;

assign bar1_sh_wready  = sh_bar1_bus.wready ;
assign sh_bar1_bus.wvalid  = sh_bar1_wvalid ;
assign sh_bar1_bus.wdata   = sh_bar1_wdata  ;
assign sh_bar1_bus.wstrb   = sh_bar1_wstrb  ;

assign bar1_sh_bvalid  = sh_bar1_bus.bvalid ;
assign bar1_sh_bresp   = sh_bar1_bus.bresp  ;
assign sh_bar1_bus.bready  = sh_bar1_bready ;

assign bar1_sh_arready = sh_bar1_bus.arready;
assign sh_bar1_bus.arvalid = sh_bar1_arvalid;
assign sh_bar1_bus.araddr  = sh_bar1_araddr ;

assign bar1_sh_rvalid  = sh_bar1_bus.rvalid ;
assign bar1_sh_rdata   = sh_bar1_bus.rdata  ;
assign bar1_sh_rresp   = sh_bar1_bus.rresp  ;
assign sh_bar1_bus.rready  = sh_bar1_rready ;


//-----------------------------------------
// BAR1 Slice
//-----------------------------------------
axi_register_slice_light BAR1_SLICE (
  .aclk          (clk),
  .aresetn       (sync_rst_n),

  // Slave in
  .s_axi_awvalid (sh_bar1_bus.awvalid  ),
  .s_axi_awready (sh_bar1_bus.awready  ),
  .s_axi_awaddr  (sh_bar1_bus.awaddr   ),

  .s_axi_wvalid  (sh_bar1_bus.wvalid   ),
  .s_axi_wready  (sh_bar1_bus.wready   ),
  .s_axi_wdata   (sh_bar1_bus.wdata    ),
  .s_axi_wstrb   (sh_bar1_bus.wstrb    ),

  .s_axi_bvalid  (sh_bar1_bus.bvalid   ),
  .s_axi_bready  (sh_bar1_bus.bready   ),
  .s_axi_bresp   (sh_bar1_bus.bresp    ),

  .s_axi_arvalid (sh_bar1_bus.arvalid  ),
  .s_axi_arready (sh_bar1_bus.arready  ),
  .s_axi_araddr  (sh_bar1_bus.araddr   ),

  .s_axi_rvalid  (sh_bar1_bus.rvalid   ),
  .s_axi_rready  (sh_bar1_bus.rready   ),
  .s_axi_rdata   (sh_bar1_bus.rdata    ),
  .s_axi_rresp   (sh_bar1_bus.rresp    ),

  // Master out
  .m_axi_awaddr  (cl_axi_slv_bus.awaddr ),
  .m_axi_awvalid (cl_axi_slv_bus.awvalid),
  .m_axi_awready (cl_axi_slv_bus.awready),

  .m_axi_wdata   (cl_axi_slv_bus.wdata  ),
  .m_axi_wstrb   (cl_axi_slv_bus.wstrb  ),
  .m_axi_wvalid  (cl_axi_slv_bus.wvalid ),
  .m_axi_wready  (cl_axi_slv_bus.wready ),

  .m_axi_bresp   (cl_axi_slv_bus.bresp  ),
  .m_axi_bvalid  (cl_axi_slv_bus.bvalid ),
  .m_axi_bready  (cl_axi_slv_bus.bready ),

  .m_axi_araddr  (cl_axi_slv_bus.araddr ),
  .m_axi_arvalid (cl_axi_slv_bus.arvalid),
  .m_axi_arready (cl_axi_slv_bus.arready),

  .m_axi_rdata   (cl_axi_slv_bus.rdata  ),
  .m_axi_rresp   (cl_axi_slv_bus.rresp  ),
  .m_axi_rvalid  (cl_axi_slv_bus.rvalid ),
  .m_axi_rready  (cl_axi_slv_bus.rready )
);

`FLETCHER_TOP #() FLETCHER_TOP_INST (
   .kcd_clk(clk),
   .bcd_clk(clk),
   .kcd_reset(!dma_pcis_slv_sync_rst_n),
   .bcd_reset(!dma_pcis_slv_sync_rst_n),

   // Master interface
   .m_axi_arvalid(cl_axi_mstr_bus.arvalid),
   .m_axi_arready(cl_axi_mstr_bus.arready),
   .m_axi_araddr (cl_axi_mstr_bus.araddr ),
   .m_axi_arlen  (cl_axi_mstr_bus.arlen  ),
   .m_axi_arsize (cl_axi_mstr_bus.arsize ),

   .m_axi_rvalid (cl_axi_mstr_bus.rvalid ),
   .m_axi_rready (cl_axi_mstr_bus.rready ),
   .m_axi_rdata  (cl_axi_mstr_bus.rdata  ),
   .m_axi_rresp  (cl_axi_mstr_bus.rresp  ),
   .m_axi_rlast  (cl_axi_mstr_bus.rlast  ),

   .m_axi_awvalid(cl_axi_mstr_bus.awvalid),
   .m_axi_awready(cl_axi_mstr_bus.awready),
   .m_axi_awaddr (cl_axi_mstr_bus.awaddr ),
   .m_axi_awlen  (cl_axi_mstr_bus.awlen  ),
   .m_axi_awsize (cl_axi_mstr_bus.awsize ),

   .m_axi_wvalid (cl_axi_mstr_bus.wvalid),
   .m_axi_wready (cl_axi_mstr_bus.wready),
   .m_axi_wdata  (cl_axi_mstr_bus.wdata ),
   .m_axi_wlast  (cl_axi_mstr_bus.wlast ),
   .m_axi_wstrb  (cl_axi_mstr_bus.wstrb ),

   .m_axi_bvalid (cl_axi_mstr_bus.bvalid),
   .m_axi_bready (cl_axi_mstr_bus.bready),
   .m_axi_bresp  (cl_axi_mstr_bus.bresp ),

   // Slave interface
   .s_axi_awvalid(cl_axi_slv_bus.awvalid),
   .s_axi_awready(cl_axi_slv_bus.awready),
   .s_axi_awaddr (cl_axi_slv_bus.awaddr ),
   .s_axi_wvalid (cl_axi_slv_bus.wvalid ),
   .s_axi_wready (cl_axi_slv_bus.wready ),
   .s_axi_wdata  (cl_axi_slv_bus.wdata  ),
   .s_axi_wstrb  (cl_axi_slv_bus.wstrb  ),
   .s_axi_bvalid (cl_axi_slv_bus.bvalid ),
   .s_axi_bready (cl_axi_slv_bus.bready ),
   .s_axi_bresp  (cl_axi_slv_bus.bresp  ),
   .s_axi_arvalid(cl_axi_slv_bus.arvalid),
   .s_axi_arready(cl_axi_slv_bus.arready),
   .s_axi_araddr (cl_axi_slv_bus.araddr ),
   .s_axi_rvalid (cl_axi_slv_bus.rvalid ),
   .s_axi_rready (cl_axi_slv_bus.rready ),
   .s_axi_rdata  (cl_axi_slv_bus.rdata  ),
   .s_axi_rresp  (cl_axi_slv_bus.rresp  )
);

///////////////////////////////////////////////////////////////////////
///////////////// Secondary AXI Master module /////////////////////////
///////////////////////////////////////////////////////////////////////


//----------------------------------------- 
// DDR controller instantiation   
//-----------------------------------------
logic [7:0] sh_ddr_stat_addr_q[2:0];
logic[2:0] sh_ddr_stat_wr_q;
logic[2:0] sh_ddr_stat_rd_q; 
logic[31:0] sh_ddr_stat_wdata_q[2:0];
logic[2:0] ddr_sh_stat_ack_q;
logic[31:0] ddr_sh_stat_rdata_q[2:0];
logic[7:0] ddr_sh_stat_int_q[2:0];


lib_pipe #(.WIDTH(1+1+8+32), .STAGES(4)) PIPE_DDR_STAT0 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
                                               .out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(4)) PIPE_DDR_STAT_ACK0 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
                                               .out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
                                               );


lib_pipe #(.WIDTH(1+1+8+32), .STAGES(4)) PIPE_DDR_STAT1 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
                                               .out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(4)) PIPE_DDR_STAT_ACK1 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
                                               .out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
                                               );

lib_pipe #(.WIDTH(1+1+8+32), .STAGES(4)) PIPE_DDR_STAT2 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
                                               .out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(4)) PIPE_DDR_STAT_ACK2 (.clk(clk), .rst_n(sync_rst_n),
                                               .in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
                                               .out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
                                               ); 

//convert to 2D 
logic[15:0] cl_sh_ddr_awid_2d[2:0];
logic[63:0] cl_sh_ddr_awaddr_2d[2:0];
logic[7:0] cl_sh_ddr_awlen_2d[2:0];
logic[2:0] cl_sh_ddr_awsize_2d[2:0];
logic[1:0] cl_sh_ddr_awburst_2d[2:0];
logic cl_sh_ddr_awvalid_2d [2:0];
logic[2:0] sh_cl_ddr_awready_2d;

logic[15:0] cl_sh_ddr_wid_2d[2:0];
logic[511:0] cl_sh_ddr_wdata_2d[2:0];
logic[63:0] cl_sh_ddr_wstrb_2d[2:0];
logic[2:0] cl_sh_ddr_wlast_2d;
logic[2:0] cl_sh_ddr_wvalid_2d;
logic[2:0] sh_cl_ddr_wready_2d;

logic[15:0] sh_cl_ddr_bid_2d[2:0];
logic[1:0] sh_cl_ddr_bresp_2d[2:0];
logic[2:0] sh_cl_ddr_bvalid_2d;
logic[2:0] cl_sh_ddr_bready_2d;

logic[15:0] cl_sh_ddr_arid_2d[2:0];
logic[63:0] cl_sh_ddr_araddr_2d[2:0];
logic[7:0] cl_sh_ddr_arlen_2d[2:0];
logic[2:0] cl_sh_ddr_arsize_2d[2:0];
logic[1:0] cl_sh_ddr_arburst_2d[2:0];
logic[2:0] cl_sh_ddr_arvalid_2d;
logic[2:0] sh_cl_ddr_arready_2d;

logic[15:0] sh_cl_ddr_rid_2d[2:0];
logic[511:0] sh_cl_ddr_rdata_2d[2:0];
logic[1:0] sh_cl_ddr_rresp_2d[2:0];
logic[2:0] sh_cl_ddr_rlast_2d;
logic[2:0] sh_cl_ddr_rvalid_2d;
logic[2:0] cl_sh_ddr_rready_2d;

assign cl_sh_ddr_awid_2d = '{lcl_cl_sh_ddrd.awid, lcl_cl_sh_ddrb.awid, lcl_cl_sh_ddra.awid};
assign cl_sh_ddr_awaddr_2d = '{lcl_cl_sh_ddrd.awaddr, lcl_cl_sh_ddrb.awaddr, lcl_cl_sh_ddra.awaddr};
assign cl_sh_ddr_awlen_2d = '{lcl_cl_sh_ddrd.awlen, lcl_cl_sh_ddrb.awlen, lcl_cl_sh_ddra.awlen};
assign cl_sh_ddr_awsize_2d = '{lcl_cl_sh_ddrd.awsize, lcl_cl_sh_ddrb.awsize, lcl_cl_sh_ddra.awsize};
assign cl_sh_ddr_awvalid_2d = '{lcl_cl_sh_ddrd.awvalid, lcl_cl_sh_ddrb.awvalid, lcl_cl_sh_ddra.awvalid};
assign cl_sh_ddr_awburst_2d = {2'b01, 2'b01, 2'b01};
assign {lcl_cl_sh_ddrd.awready, lcl_cl_sh_ddrb.awready, lcl_cl_sh_ddra.awready} = sh_cl_ddr_awready_2d;

assign cl_sh_ddr_wid_2d = '{lcl_cl_sh_ddrd.wid, lcl_cl_sh_ddrb.wid, lcl_cl_sh_ddra.wid};
assign cl_sh_ddr_wdata_2d = '{lcl_cl_sh_ddrd.wdata, lcl_cl_sh_ddrb.wdata, lcl_cl_sh_ddra.wdata};
assign cl_sh_ddr_wstrb_2d = '{lcl_cl_sh_ddrd.wstrb, lcl_cl_sh_ddrb.wstrb, lcl_cl_sh_ddra.wstrb};
assign cl_sh_ddr_wlast_2d = {lcl_cl_sh_ddrd.wlast, lcl_cl_sh_ddrb.wlast, lcl_cl_sh_ddra.wlast};
assign cl_sh_ddr_wvalid_2d = {lcl_cl_sh_ddrd.wvalid, lcl_cl_sh_ddrb.wvalid, lcl_cl_sh_ddra.wvalid};
assign {lcl_cl_sh_ddrd.wready, lcl_cl_sh_ddrb.wready, lcl_cl_sh_ddra.wready} = sh_cl_ddr_wready_2d;

assign {lcl_cl_sh_ddrd.bid, lcl_cl_sh_ddrb.bid, lcl_cl_sh_ddra.bid} = {sh_cl_ddr_bid_2d[2], sh_cl_ddr_bid_2d[1], sh_cl_ddr_bid_2d[0]};
assign {lcl_cl_sh_ddrd.bresp, lcl_cl_sh_ddrb.bresp, lcl_cl_sh_ddra.bresp} = {sh_cl_ddr_bresp_2d[2], sh_cl_ddr_bresp_2d[1], sh_cl_ddr_bresp_2d[0]};
assign {lcl_cl_sh_ddrd.bvalid, lcl_cl_sh_ddrb.bvalid, lcl_cl_sh_ddra.bvalid} = sh_cl_ddr_bvalid_2d;
assign cl_sh_ddr_bready_2d = {lcl_cl_sh_ddrd.bready, lcl_cl_sh_ddrb.bready, lcl_cl_sh_ddra.bready};

assign cl_sh_ddr_arid_2d = '{lcl_cl_sh_ddrd.arid, lcl_cl_sh_ddrb.arid, lcl_cl_sh_ddra.arid};
assign cl_sh_ddr_araddr_2d = '{lcl_cl_sh_ddrd.araddr, lcl_cl_sh_ddrb.araddr, lcl_cl_sh_ddra.araddr};
assign cl_sh_ddr_arlen_2d = '{lcl_cl_sh_ddrd.arlen, lcl_cl_sh_ddrb.arlen, lcl_cl_sh_ddra.arlen};
assign cl_sh_ddr_arsize_2d = '{lcl_cl_sh_ddrd.arsize, lcl_cl_sh_ddrb.arsize, lcl_cl_sh_ddra.arsize};
assign cl_sh_ddr_arvalid_2d = {lcl_cl_sh_ddrd.arvalid, lcl_cl_sh_ddrb.arvalid, lcl_cl_sh_ddra.arvalid};
assign cl_sh_ddr_arburst_2d = {2'b01, 2'b01, 2'b01};
assign {lcl_cl_sh_ddrd.arready, lcl_cl_sh_ddrb.arready, lcl_cl_sh_ddra.arready} = sh_cl_ddr_arready_2d;

assign {lcl_cl_sh_ddrd.rid, lcl_cl_sh_ddrb.rid, lcl_cl_sh_ddra.rid} = {sh_cl_ddr_rid_2d[2], sh_cl_ddr_rid_2d[1], sh_cl_ddr_rid_2d[0]};
assign {lcl_cl_sh_ddrd.rresp, lcl_cl_sh_ddrb.rresp, lcl_cl_sh_ddra.rresp} = {sh_cl_ddr_rresp_2d[2], sh_cl_ddr_rresp_2d[1], sh_cl_ddr_rresp_2d[0]};
assign {lcl_cl_sh_ddrd.rdata, lcl_cl_sh_ddrb.rdata, lcl_cl_sh_ddra.rdata} = {sh_cl_ddr_rdata_2d[2], sh_cl_ddr_rdata_2d[1], sh_cl_ddr_rdata_2d[0]};
assign {lcl_cl_sh_ddrd.rlast, lcl_cl_sh_ddrb.rlast, lcl_cl_sh_ddra.rlast} = sh_cl_ddr_rlast_2d;
assign {lcl_cl_sh_ddrd.rvalid, lcl_cl_sh_ddrb.rvalid, lcl_cl_sh_ddra.rvalid} = sh_cl_ddr_rvalid_2d;
assign cl_sh_ddr_rready_2d = {lcl_cl_sh_ddrd.rready, lcl_cl_sh_ddrb.rready, lcl_cl_sh_ddra.rready};

(* dont_touch = "true" *) logic sh_ddr_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SH_DDR_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(sh_ddr_sync_rst_n));
sh_ddr #(
         .DDR_A_PRESENT(`DDR_A_PRESENT),
         .DDR_B_PRESENT(`DDR_B_PRESENT),
         .DDR_D_PRESENT(`DDR_D_PRESENT)
   ) SH_DDR
   (
   .clk(clk),
   .rst_n(sh_ddr_sync_rst_n),

   .stat_clk(clk),
   .stat_rst_n(sh_ddr_sync_rst_n),


   .CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
   .CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
   .M_A_ACT_N(M_A_ACT_N),
   .M_A_MA(M_A_MA),
   .M_A_BA(M_A_BA),
   .M_A_BG(M_A_BG),
   .M_A_CKE(M_A_CKE),
   .M_A_ODT(M_A_ODT),
   .M_A_CS_N(M_A_CS_N),
   .M_A_CLK_DN(M_A_CLK_DN),
   .M_A_CLK_DP(M_A_CLK_DP),
   .M_A_PAR(M_A_PAR),
   .M_A_DQ(M_A_DQ),
   .M_A_ECC(M_A_ECC),
   .M_A_DQS_DP(M_A_DQS_DP),
   .M_A_DQS_DN(M_A_DQS_DN),
   .cl_RST_DIMM_A_N(cl_RST_DIMM_A_N),
   
   
   .CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
   .CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
   .M_B_ACT_N(M_B_ACT_N),
   .M_B_MA(M_B_MA),
   .M_B_BA(M_B_BA),
   .M_B_BG(M_B_BG),
   .M_B_CKE(M_B_CKE),
   .M_B_ODT(M_B_ODT),
   .M_B_CS_N(M_B_CS_N),
   .M_B_CLK_DN(M_B_CLK_DN),
   .M_B_CLK_DP(M_B_CLK_DP),
   .M_B_PAR(M_B_PAR),
   .M_B_DQ(M_B_DQ),
   .M_B_ECC(M_B_ECC),
   .M_B_DQS_DP(M_B_DQS_DP),
   .M_B_DQS_DN(M_B_DQS_DN),
   .cl_RST_DIMM_B_N(cl_RST_DIMM_B_N),

   .CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
   .CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
   .M_D_ACT_N(M_D_ACT_N),
   .M_D_MA(M_D_MA),
   .M_D_BA(M_D_BA),
   .M_D_BG(M_D_BG),
   .M_D_CKE(M_D_CKE),
   .M_D_ODT(M_D_ODT),
   .M_D_CS_N(M_D_CS_N),
   .M_D_CLK_DN(M_D_CLK_DN),
   .M_D_CLK_DP(M_D_CLK_DP),
   .M_D_PAR(M_D_PAR),
   .M_D_DQ(M_D_DQ),
   .M_D_ECC(M_D_ECC),
   .M_D_DQS_DP(M_D_DQS_DP),
   .M_D_DQS_DN(M_D_DQS_DN),
   .cl_RST_DIMM_D_N(cl_RST_DIMM_D_N),

   //------------------------------------------------------
   // DDR-4 Interface from CL (AXI-4)
   //------------------------------------------------------
   .cl_sh_ddr_awid(cl_sh_ddr_awid_2d),
   .cl_sh_ddr_awaddr(cl_sh_ddr_awaddr_2d),
   .cl_sh_ddr_awlen(cl_sh_ddr_awlen_2d),
   .cl_sh_ddr_awsize(cl_sh_ddr_awsize_2d),
   .cl_sh_ddr_awvalid(cl_sh_ddr_awvalid_2d),
   .cl_sh_ddr_awburst(cl_sh_ddr_awburst_2d),
   .sh_cl_ddr_awready(sh_cl_ddr_awready_2d),

   .cl_sh_ddr_wid(cl_sh_ddr_wid_2d),
   .cl_sh_ddr_wdata(cl_sh_ddr_wdata_2d),
   .cl_sh_ddr_wstrb(cl_sh_ddr_wstrb_2d),
   .cl_sh_ddr_wlast(cl_sh_ddr_wlast_2d),
   .cl_sh_ddr_wvalid(cl_sh_ddr_wvalid_2d),
   .sh_cl_ddr_wready(sh_cl_ddr_wready_2d),

   .sh_cl_ddr_bid(sh_cl_ddr_bid_2d),
   .sh_cl_ddr_bresp(sh_cl_ddr_bresp_2d),
   .sh_cl_ddr_bvalid(sh_cl_ddr_bvalid_2d),
   .cl_sh_ddr_bready(cl_sh_ddr_bready_2d),

   .cl_sh_ddr_arid(cl_sh_ddr_arid_2d),
   .cl_sh_ddr_araddr(cl_sh_ddr_araddr_2d),
   .cl_sh_ddr_arlen(cl_sh_ddr_arlen_2d),
   .cl_sh_ddr_arsize(cl_sh_ddr_arsize_2d),
   .cl_sh_ddr_arvalid(cl_sh_ddr_arvalid_2d),
   .cl_sh_ddr_arburst(cl_sh_ddr_arburst_2d),
   .sh_cl_ddr_arready(sh_cl_ddr_arready_2d),

   .sh_cl_ddr_rid(sh_cl_ddr_rid_2d),
   .sh_cl_ddr_rdata(sh_cl_ddr_rdata_2d),
   .sh_cl_ddr_rresp(sh_cl_ddr_rresp_2d),
   .sh_cl_ddr_rlast(sh_cl_ddr_rlast_2d),
   .sh_cl_ddr_rvalid(sh_cl_ddr_rvalid_2d),
   .cl_sh_ddr_rready(cl_sh_ddr_rready_2d),

   .sh_cl_ddr_is_ready(lcl_sh_cl_ddr_is_ready),

   .sh_ddr_stat_addr0  (sh_ddr_stat_addr_q[0]) ,
   .sh_ddr_stat_wr0    (sh_ddr_stat_wr_q[0]     ) , 
   .sh_ddr_stat_rd0    (sh_ddr_stat_rd_q[0]     ) , 
   .sh_ddr_stat_wdata0 (sh_ddr_stat_wdata_q[0]  ) , 
   .ddr_sh_stat_ack0   (ddr_sh_stat_ack_q[0]    ) ,
   .ddr_sh_stat_rdata0 (ddr_sh_stat_rdata_q[0]  ),
   .ddr_sh_stat_int0   (ddr_sh_stat_int_q[0]    ),

   .sh_ddr_stat_addr1  (sh_ddr_stat_addr_q[1]) ,
   .sh_ddr_stat_wr1    (sh_ddr_stat_wr_q[1]     ) , 
   .sh_ddr_stat_rd1    (sh_ddr_stat_rd_q[1]     ) , 
   .sh_ddr_stat_wdata1 (sh_ddr_stat_wdata_q[1]  ) , 
   .ddr_sh_stat_ack1   (ddr_sh_stat_ack_q[1]    ) ,
   .ddr_sh_stat_rdata1 (ddr_sh_stat_rdata_q[1]  ),
   .ddr_sh_stat_int1   (ddr_sh_stat_int_q[1]    ),

   .sh_ddr_stat_addr2  (sh_ddr_stat_addr_q[2]) ,
   .sh_ddr_stat_wr2    (sh_ddr_stat_wr_q[2]     ) , 
   .sh_ddr_stat_rd2    (sh_ddr_stat_rd_q[2]     ) , 
   .sh_ddr_stat_wdata2 (sh_ddr_stat_wdata_q[2]  ) , 
   .ddr_sh_stat_ack2   (ddr_sh_stat_ack_q[2]    ) ,
   .ddr_sh_stat_rdata2 (ddr_sh_stat_rdata_q[2]  ),
   .ddr_sh_stat_int2   (ddr_sh_stat_int_q[2]    )
   );

//----------------------------------------- 
// DDR controller instantiation   
//-----------------------------------------

//----------------------------------------- 
// Virtual JTAG ILA Debug core example 
//-----------------------------------------


`ifndef DISABLE_VJTAG_DEBUG

   cl_ila #(.DDR_A_PRESENT(`DDR_A_PRESENT) ) CL_ILA   (

   .aclk(clk),
   .drck(drck),
   .shift(shift),
      .tdi(tdi),
   .update(update),
   .sel(sel),
   .tdo(tdo),
   .tms(tms),
   .tck(tck),
   .runtest(runtest),
   .reset(reset),
   .capture(capture),
   .bscanid_en(bscanid_en),
   .sh_cl_dma_pcis_q(sh_cl_dma_pcis_q),
`ifndef DDR_A_ABSENT   
   .lcl_cl_sh_ddra(lcl_cl_sh_ddra)
`else
   .lcl_cl_sh_ddra(axi_bus_tied)
`endif
);

cl_vio CL_VIO (

   .clk_extra_a1(clk_extra_a1)

);


`endif //  `ifndef DISABLE_VJTAG_DEBUG

//----------------------------------------- 
// Virtual JATG ILA Debug core example 
//-----------------------------------------
// tie off for ILA port when probing block not present
   assign axi_bus_tied.awvalid = 1'b0 ;
   assign axi_bus_tied.awaddr = 64'b0 ;
   assign axi_bus_tied.awready = 1'b0 ;
   assign axi_bus_tied.wvalid = 1'b0 ;
   assign axi_bus_tied.wstrb = 64'b0 ;
   assign axi_bus_tied.wlast = 1'b0 ;
   assign axi_bus_tied.wready = 1'b0 ;
   assign axi_bus_tied.wdata = 512'b0 ;
   assign axi_bus_tied.arready = 1'b0 ;
   assign axi_bus_tied.rdata = 512'b0 ;
   assign axi_bus_tied.araddr = 64'b0 ;
   assign axi_bus_tied.arvalid = 1'b0 ;
   assign axi_bus_tied.awid = 16'b0 ;
   assign axi_bus_tied.arid = 16'b0 ;
   assign axi_bus_tied.awlen = 8'b0 ;
   assign axi_bus_tied.rlast = 1'b0 ;
   assign axi_bus_tied.rresp = 2'b0 ;
   assign axi_bus_tied.rid = 16'b0 ;
   assign axi_bus_tied.rvalid = 1'b0 ;
   assign axi_bus_tied.arlen = 8'b0 ;
   assign axi_bus_tied.bresp = 2'b0 ;
   assign axi_bus_tied.rready = 1'b0 ;
   assign axi_bus_tied.bvalid = 1'b0 ;
   assign axi_bus_tied.bid = 16'b0 ;
   assign axi_bus_tied.bready = 1'b0 ;


endmodule   