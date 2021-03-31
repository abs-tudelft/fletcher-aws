add_compile_unit(
  NAME fletcher::aws
  TYPE SHARED
  COMPONENT library
  PRPS
    C_STANDARD 99
  SRCS
    src/fletcher_aws.c
  DEPS
    fletcher::c
    fpga_mgmt
)
