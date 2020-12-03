cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(fletcher_aws VERSION 0.0.0 LANGUAGES C CXX)

include(ExternalProject)

cmake_policy(SET CMP0097 NEW)
ExternalProject_Add(aws-fpga
  GIT_REPOSITORY    https://github.com/aws/aws-fpga.git
  GIT_TAG           v1.4.17
  GIT_SHALLOW       ON
  GIT_SUBMODULES    ""
  CONFIGURE_COMMAND ""
  SOURCE_SUBDIR     sdk/userspace
  BUILD_IN_SOURCE   ON
  BUILD_COMMAND     ./mkall_fpga_mgmt_tools.sh
  INSTALL_COMMAND   ""
)
# ExternalProject_Add_StepTargets(aws-fpga build)
ExternalProject_Get_property(aws-fpga SOURCE_DIR)

add_library(fpga_mgmt_include INTERFACE)
target_include_directories(fpga_mgmt_include INTERFACE ${SOURCE_DIR}/sdk/userspace/include)
add_library(fpga_mgmt SHARED IMPORTED)  
add_dependencies(fpga_mgmt aws-fpga)
set_target_properties(fpga_mgmt PROPERTIES 
  IMPORTED_LOCATION ${SOURCE_DIR}/sdk/userspace/lib/so/libfpga_mgmt.so
)
target_link_libraries(fpga_mgmt_include INTERFACE fpga_mgmt)

include(FetchContent)

FetchContent_Declare(cmake-modules
  GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
  GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

FetchContent_Declare(fletcher
  GIT_REPOSITORY  https://github.com/abs-tudelft/fletcher.git
  GIT_TAG         0.0.13
)
if(NOT fletcher_POPULATED)
  FetchContent_Populate(fletcher)
  add_subdirectory(${fletcher_SOURCE_DIR}/common/c ${fletcher_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

include(CompileUnits)

add_compile_unit(
  NAME fletcher::aws
  TYPE SHARED
  PRPS
    C_STANDARD 99
  SRCS
    src/fletcher_aws.c
  DEPS
    fletcher::c
    fpga_mgmt_include
)

compile_units()
