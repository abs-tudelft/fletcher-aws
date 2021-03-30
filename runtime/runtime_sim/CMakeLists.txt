add_compile_unit(
  OPT
  NAME fletcher::aws-sim
  TYPE SHARED
  COMPONENT sim
  PRPS
    C_STANDARD 99
  SRCS
    src/fletcher_aws_sim.c
    ${SOURCE_DIR}/hdk/common/software/src/fpga_pci_sv.c
  DEPS
    fletcher::c
    fpga_pci_sv
)
