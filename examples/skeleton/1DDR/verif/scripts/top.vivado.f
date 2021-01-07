# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

--define VIVADO_SIM

--sourcelibext .v
--sourcelibext .sv
--sourcelibext .svh

--sourcelibdir ${CL_ROOT}/design
--sourcelibdir ${SH_LIB_DIR}
--sourcelibdir ${SH_INF_DIR}
--sourcelibdir ${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim

--include ${CL_ROOT}/design
--include ${CL_ROOT}/verif/sv

--include ${SH_LIB_DIR}
--include ${SH_INF_DIR}
--include ${HDK_COMMON_DIR}/verif/include
--include ${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/sim
--include ${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/hdl/verilog
--include ${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice/hdl
--include ${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/hdl
--include ${CL_ROOT}/design/axi_crossbar_0
--include ${HDK_SHELL_DESIGN_DIR}/ip/cl_axi_interconnect/ipshared/7e3a/hdl
--include ${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim

#needs to be first, to define CL_NAME
${CL_ROOT}/design/cl_dram_dma_defines.vh

-f ${HDK_COMMON_DIR}/verif/tb/filelists/tb.${SIMULATOR}.f
${TEST_NAME}

${HDK_SHELL_DESIGN_DIR}/ip/axi_clock_converter_0/sim/axi_clock_converter_0.v
${HDK_SHELL_DESIGN_DIR}/ip/dest_register_slice/sim/dest_register_slice.v
${HDK_SHELL_DESIGN_DIR}/ip/src_register_slice/sim/src_register_slice.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice/sim/axi_register_slice.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/sim/axi_register_slice_light.v
${HDK_SHELL_DESIGN_DIR}/ip/dest_register_slice/hdl/axi_register_slice_v2_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_clock_converter_0/hdl/axi_clock_converter_v2_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_clock_converter_0/hdl/fifo_generator_v13_2_rfs.v

#IP files from our design-specific axi_interconnect
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ipshared/4d88/hdl/axi_register_slice_v2_1_vl_rfs.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ipshared/5b9c/hdl/axi_data_fifo_v2_1_vl_rfs.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ipshared/ace7/hdl/axi_crossbar_v2_1_vl_rfs.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ip/cl_axi_interconnect_xbar_0/sim/cl_axi_interconnect_xbar_0.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ip/cl_axi_interconnect_s00_regslice_0/sim/cl_axi_interconnect_s00_regslice_0.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ip/cl_axi_interconnect_s01_regslice_0/sim/cl_axi_interconnect_s01_regslice_0.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/ip/cl_axi_interconnect_m00_regslice_0/sim/cl_axi_interconnect_m00_regslice_0.v
${CL_ROOT}/ip/cl_axi_interconnect_1m2s/sim/cl_axi_interconnect.v


${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_bi_delay.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_db_delay_model.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_db_dly_dir.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_dir_detect.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_rcd_model.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_rank.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_dimm.sv
${HDK_COMMON_DIR}/verif/models/ddr4_rdimm_wrapper/ddr4_rdimm_wrapper.sv 
${SH_LIB_DIR}/bram_2rw.sv
${SH_LIB_DIR}/flop_fifo.sv
${SH_LIB_DIR}/lib_pipe.sv
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/mgt_gen_axl.sv
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/ccf_ctl.v
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/mgt_acc_axl.sv
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/sync.v
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/flop_ccf.sv
${HDK_SHELL_DESIGN_DIR}/sh_ddr/sim/sh_ddr.sv


--define DISABLE_VJTAG_DEBUG
${CL_ROOT}/design/cl_dram_dma_pkg.sv
${CL_ROOT}/design/cl_dma_pcis_slv.sv
${CL_ROOT}/design/cl_ila.sv
${CL_ROOT}/design/cl_vio.sv
${CL_ROOT}/design/cl_fletcher_aws_1DDR.sv

