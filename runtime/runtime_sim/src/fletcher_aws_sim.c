// Copyright 2018 Delft University of Technology
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "fletcher/fletcher.h"
#include "fletcher_aws_sim_private.h"

#include <fpga_pci_sv.h>
#include <utils/sh_dpi_tasks.h>

// Dirty globals
PlatformState aws_state = {FLETCHER_AWS_DEVICE_ALIGNMENT, 0, 0x0};
InitOptions options = FLETCHER_AWS_SIM_CONFIG_DEFAULT;

static fstatus_t check_ddr(const uint8_t *source, da_t offset, size_t size) {
  uint8_t *check_buffer = (uint8_t*)malloc(size);
  sv_fpga_start_cl_to_buffer(0, 0, size, (uint64_t)check_buffer, offset);
  int ret = memcmp(source, check_buffer, size);
  free(check_buffer);
  return (ret == 0) ? FLETCHER_STATUS_OK : FLETCHER_STATUS_ERROR;
}

fstatus_t platformGetName(char *name, size_t size) {
  size_t len = strlen(FLETCHER_PLATFORM_NAME);
  if (len > size) {
    memcpy(name, FLETCHER_PLATFORM_NAME, size - 1);
    name[size - 1] = '\0';
  } else {
    memcpy(name, FLETCHER_PLATFORM_NAME, len + 1);
  }
  return FLETCHER_STATUS_OK;
}

fstatus_t platformInit(void *arg) {

  if (arg != NULL) {
    options = *(InitOptions*)arg;
  }
  aws_state.buffer_ptr = 0x400000000ull * options.ddr_bank;

  debug_print("[FLETCHER_AWS_SIM] Initializing platform.       Arguments @ [host] %016lX.\n", (unsigned long) arg);

  /* The statements within SCOPE ifdef below are needed for HW/SW
   * co-simulation with VCS */
#if defined(SCOPE)
  svScope scope;
  scope = svGetScopeFromName("tb");
  svSetScope(scope);
#endif

  return FLETCHER_STATUS_OK;
}

fstatus_t platformWriteMMIO(uint64_t offset, uint32_t value) {
  cl_poke_bar1(sizeof(uint32_t) * offset, value);
  debug_print("[FLETCHER_AWS_SIM] MMIO Write %d : %08X\n", (uint32_t) offset, (uint32_t) value);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformReadMMIO(uint64_t offset, uint32_t *value) {
  *value = 0xDEADBEEF;
  int rc = 0;
  cl_peek_bar1(sizeof(uint32_t) * offset, value);
  debug_print("[FLETCHER_AWS_SIM] MMIO Read %d : %08X\n", (uint32_t) offset, (uint32_t)(*value));
  return FLETCHER_STATUS_OK;
}

fstatus_t platformCopyHostToDevice(const uint8_t *host_source, da_t device_destination, int64_t size) {
  size_t total = 0;

  debug_print(
    "[FLETCHER_AWS_SIM] Copying host to device %016lX -> %016lX (%li bytes).\n",
    (uint64_t) host_source,
    (uint64_t) device_destination,
    size
  );

  sv_fpga_start_buffer_to_cl(0, 0, size, (uint64_t) host_source, device_destination);

#ifdef DEBUG
  fstatus_t ddr_check = check_ddr(host_source, device_destination, size);
  if (ddr_check != FLETCHER_STATUS_OK) {
    fprintf(stderr, "[FLETCHER_AWS_SIM] Copied buffer in DDR differs from host buffer.\n");
  }
  return ddr_check;
#endif

  return FLETCHER_STATUS_OK;
}

fstatus_t platformCopyDeviceToHost(da_t device_source, uint8_t *host_destination, int64_t size) {
  size_t total = 0;

  debug_print(
    "[FLETCHER_AWS_SIM] Copying device to host %016lX -> %016lX (%li bytes).\n",
    (uint64_t) device_source,
    (uint64_t) host_destination,
    size
  );

  sv_fpga_start_cl_to_buffer(0, 0, size, (uint64_t) host_destination, device_source);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformTerminate(void *arg) {
  debug_print("[FLETCHER_AWS_SIM] Terminating platform (no-op).\n", (uint64_t) arg);

  return FLETCHER_STATUS_OK;
}

fstatus_t platformDeviceMalloc(da_t *device_address, int64_t size) {
  *device_address = aws_state.buffer_ptr;
  debug_print(
    "[FLETCHER_AWS_SIM] Allocating device memory.    [device] 0x%016lX (%10lu bytes).\n",
    (uint64_t) aws_state.buffer_ptr,
    size
  );
  aws_state.buffer_ptr += size + FLETCHER_AWS_DEVICE_ALIGNMENT - (size % FLETCHER_AWS_DEVICE_ALIGNMENT);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformDeviceFree(da_t device_address) {
  debug_print(
    "[FLETCHER_AWS_SIM] Freeing device memory.       [device] 0x%016lX : NOT IMPLEMENTED.\n",
    device_address
  );
  return FLETCHER_STATUS_OK;
}

fstatus_t platformPrepareHostBuffer(const uint8_t *host_source, da_t *device_destination, int64_t size, int *alloced) {
  debug_print("[FLETCHER_AWS_SIM] Prepare is equal to cache on AWS f1.\n");
  *alloced = 1;
  return platformCacheHostBuffer(host_source, device_destination, size);
}

fstatus_t platformCacheHostBuffer(const uint8_t *host_source, da_t *device_destination, int64_t size) {
  *device_destination = aws_state.buffer_ptr;
  debug_print(
    "[FLETCHER_AWS_SIM] Caching buffer on device.    [host] 0x%016lX --> 0x%016lX (%10lu bytes).\n",
    (unsigned long) host_source,
    (unsigned long) *device_destination,
    size
  );
  fstatus_t ret = platformCopyHostToDevice(host_source, aws_state.buffer_ptr, size);
  *device_destination = aws_state.buffer_ptr;
  aws_state.buffer_ptr += size + (FLETCHER_AWS_DEVICE_ALIGNMENT - (size % FLETCHER_AWS_DEVICE_ALIGNMENT));
  return ret;
}

