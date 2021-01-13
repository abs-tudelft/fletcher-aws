cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(fletcher_aws_sim VERSION 0.0.0 LANGUAGES C CXX)

find_library(AWS_FPGA fpga_mgmt HINTS "$ENV{SDK_DIR}/userspace/lib/so")
if(AWS_FPGA)
  add_library(fpga_mgmt INTERFACE IMPORTED GLOBAL)
  target_include_directories(fpga_mgmt INTERFACE "$ENV{SDK_DIR}/userspace/include")
  add_library(fpga_pci_sv INTERFACE IMPORTED GLOBAL)
  target_include_directories(fpga_pci_sv INTERFACE "$ENV{HDK_DIR}/common/software/include")
else()
  message(FATAL_ERROR "Dependency fpga_mgmt not found")
endif()

include(FetchContent)

FetchContent_Declare(cmake-modules
  GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
  GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

add_subdirectory(../../fletcher/common/c c)

include(CompileUnits)

add_compile_unit(
  NAME fletcher::aws_sim
  TYPE SHARED
  PRPS
    C_STANDARD 99
  SRCS
    src/fletcher_aws_sim.c
  DEPS
    fletcher::c
    fpga_mgmt
    fpga_pci_sv
)


compile_units()
