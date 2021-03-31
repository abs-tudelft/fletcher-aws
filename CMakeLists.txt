cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(fletcher_aws
  VERSION 0.2.0
  DESCRIPTION "Fletcher platform support for Amazon AWS F1"
  HOMEPAGE_URL "https://github.com/abs-tudelft/fletcher-aws"
  LANGUAGES C
)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "")
endif()

include(FetchContent)

FetchContent_Declare(cmake-modules
  GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
  GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

FetchContent_Declare(fletcher
  GIT_REPOSITORY  https://github.com/abs-tudelft/fletcher.git
  GIT_TAG         0.0.19
)
if(NOT fletcher_POPULATED)
  FetchContent_Populate(fletcher)
  add_subdirectory(${fletcher_SOURCE_DIR}/common/c ${fletcher_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

include(CompileUnits)

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
  BUILD_BYPRODUCTS  <SOURCE_DIR>/hdk/common/software/src/fpga_pci_sv.c
  INSTALL_COMMAND   ""
)
ExternalProject_Get_property(aws-fpga SOURCE_DIR)

add_library(fpga_mgmt INTERFACE)
target_include_directories(fpga_mgmt INTERFACE ${SOURCE_DIR}/sdk/userspace/include)

add_library(fpga_mgmt_shared SHARED IMPORTED)
add_dependencies(fpga_mgmt_shared aws-fpga)
set_target_properties(fpga_mgmt_shared PROPERTIES IMPORTED_LOCATION ${SOURCE_DIR}/sdk/userspace/lib/so/libfpga_mgmt.so)
target_link_libraries(fpga_mgmt INTERFACE fpga_mgmt_shared)

add_library(fpga_pci_sv INTERFACE)
add_dependencies(fpga_pci_sv aws-fpga)
target_include_directories(fpga_pci_sv INTERFACE
  ${SOURCE_DIR}/sdk/userspace/include
  ${SOURCE_DIR}/hdk/common/software/include
)

add_subdirectory(runtime)

compile_units()

execute_process (
    COMMAND bash -c "awk -F= '/^ID=/{print $2}' /etc/os-release |tr -d '\n' | tr -d '\"'"
    OUTPUT_VARIABLE OS_NAME
)

execute_process (
    COMMAND bash -c "awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release |tr -d '\n' | tr -d '\"'"
    OUTPUT_VARIABLE OS_VERSION
)

if(OS_NAME MATCHES "ubuntu")
  set(CPACK_DEBIAN_PACKAGE_RELEASE "ubuntu${OS_VERSION}")
  set(CPACK_GENERATOR "DEB")
elseif(OS_NAME MATCHES "centos")
  set(CPACK_RPM_PACKAGE_RELEASE_DIST "el${OS_VERSION}")
  if(OS_VERSION MATCHES "7")
    set(CPACK_GENERATOR "RPM;TGZ")
  else()
    set(CPACK_GENERATOR "RPM")
  endif()
endif()

if(BUILD_FLETCHER_AWS-SIM)
  set(CPACK_COMPONENTS_ALL sim)
else()
  set(CPACK_COMPONENTS_ALL library)
  set(CPACK_RPM_MAIN_COMPONENT "library")
endif()

set(CPACK_PACKAGE_VENDOR "ABS TUDelft")
set(CPACK_PACKAGE_VERSION_MAJOR "${fletcher_aws_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${fletcher_aws_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${fletcher_aws_VERSION_PATCH}")
set(CPACK_PACKAGE_RELOCATABLE ON)

set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_DEBIAN_LIBRARY_PACKAGE_NAME "${CMAKE_PROJECT_NAME}")
set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")
set(CPACK_DEBIAN_LIBRARY_PACKAGE_DEPENDS "fletcher (>= 0.0.19)")
set(CPACK_DEBIAN_SIM_PACKAGE_DEPENDS "fletcher (>= 0.0.19)")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR}")

set(CPACK_RPM_COMPONENT_INSTALL ON)
set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")
set(CPACK_RPM_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
set(CPACK_RPM_PACKAGE_LICENSE "ASL 2.0")
set(CPACK_RPM_LIBRARY_PACKAGE_REQUIRES "fletcher >= 0.0.19")
set(CPACK_RPM_SIM_PACKAGE_REQUIRES "fletcher >= 0.0.19")

set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_ARCHIVE_LIBRARY_FILE_NAME "${CMAKE_PROJECT_NAME}-${fletcher_aws_VERSION}-${CMAKE_SYSTEM_NAME}")
set(CPACK_ARCHIVE_SIM_FILE_NAME "${CMAKE_PROJECT_NAME}-sim-${fletcher_aws_VERSION}-${CMAKE_SYSTEM_NAME}")

include(CPack)