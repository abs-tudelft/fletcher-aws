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

# TODO:
# Add check if CL_DIR and HDK_SHELL_DIR directories exist
# Add check if /build and /build/src_port_encryption directories exist
# Add check if the vivado_keyfile exist

set HDK_SHELL_DIR $::env(HDK_SHELL_DIR)
set HDK_SHELL_DESIGN_DIR $::env(HDK_SHELL_DESIGN_DIR)
set CL_DIR $::env(CL_DIR)

set TARGET_DIR $CL_DIR/build/src_post_encryption
set UNUSED_TEMPLATES_DIR $HDK_SHELL_DESIGN_DIR/interfaces


# Remove any previously encrypted files, that may no longer be used
if {[llength [glob -nocomplain -dir $TARGET_DIR *]] != 0} {
  eval file delete -force [glob $TARGET_DIR/*]
}

#---- Developr would replace this section with design files ----

## Change file names and paths below to reflect your CL area.  DO NOT include AWS RTL files.

file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilMisc_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilInt_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilConv_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/Stream_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/interconnect/Interconnect_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/axi/AxiReadConverter.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayCmdCtrlMerger.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/vhdmmio_pkg.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/mmio_pkg.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/mmio.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/Sum.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayConfigParse_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayConfig_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/Array_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/Sum_Nucleus.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamArb.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/interconnect/BusReadArbiterVec.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderStruct.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/Buffer_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderNull.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderListPrim.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilStr_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/interconnect/BusReadBuffer.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReaderRespCtrl.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReaderResp.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamGearboxSerializer.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamGearboxParallelizer.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamGearbox.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReaderPost.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReaderCmdGenBusReq.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReaderCmd.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/buffers/BufferReader.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderUnlockCombine.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamSync.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamNormalizer.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamSlice.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilRam1R1W.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamFIFOCounter.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/util/UtilRam_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamFIFO.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/vhlib/stream/StreamBuffer.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderListSyncDecoder.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderListSync.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderList.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderLevel.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReaderArb.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/arrays/ArrayReader.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/Sum_ExampleBatch.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/Sum_Mantle.gen.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/fletcher/fletcher/hardware/axi/Axi_pkg.vhd $TARGET_DIR
file copy -force /home/jjhoozemans/workspaces/aws_f1/subsurface/cache/fletcher-aws/examples/sum/design/vhdl/AxiTop.gen.vhd $TARGET_DIR


file copy -force $CL_DIR/design/cl_fletcher_aws_defines.vh                              $TARGET_DIR
file copy -force $CL_DIR/design/cl_id_defines.vh                                        $TARGET_DIR
file copy -force $CL_DIR/design/cl_fletcher_aws_pkg.sv                                  $TARGET_DIR
file copy -force $CL_DIR/design/cl_fletcher_aws.sv                                      $TARGET_DIR
file copy -force $CL_DIR/design/cl_vio.sv                                               $TARGET_DIR
file copy -force $CL_DIR/design/cl_dma_pcis_slv.sv                                      $TARGET_DIR
file copy -force $CL_DIR/design/cl_ila.sv                                               $TARGET_DIR
#---- End of section replaced by Developr ---



# Make sure files have write permissions for the encryption

exec chmod +w {*}[glob $TARGET_DIR/*]

set TOOL_VERSION $::env(VIVADO_TOOL_VERSION)
set vivado_version [string range [version -short] 0 5]
puts "AWS FPGA: VIVADO_TOOL_VERSION $TOOL_VERSION"
puts "vivado_version $vivado_version"

# encrypt .v/.sv/.vh/inc as verilog files
encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_keyfile_2017_4.txt -lang verilog -quiet [glob -nocomplain -- $TARGET_DIR/*.{v,sv}] [glob -nocomplain -- $TARGET_DIR/*.vh] [glob -nocomplain -- $TARGET_DIR/*.inc]
# encrypt *vhdl files
encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_vhdl_keyfile_2017_4.txt -lang vhdl -quiet [ glob -nocomplain -- $TARGET_DIR/*.vhd? ]
