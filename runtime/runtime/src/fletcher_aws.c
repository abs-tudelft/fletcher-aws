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
#include "fletcher_aws.h"

static const uint16_t AMZ_PCI_VENDOR_ID = 0x1D0F; /* Amazon PCI Vendor ID */
static const uint16_t PCI_DEVICE_ID = 0xF001;

// Dirty globals
AwsConfig aws_default_config = {0, 0, 1}; // Slot 0, BAR1
PlatformState aws_state = {{0, 0, 1}, 4096, {0}, {0},  0, 0, 0x0};

static fstatus_t check_ddr(const uint8_t *source, da_t offset, size_t size) {
  uint8_t *check_buffer = (uint8_t *) malloc(size);
  int rc = fpga_dma_burst_read(aws_state.xdma_rd_fd[0], check_buffer, size,
            offset);
  if (rc < 0) {
    fprintf(stderr, "[FLETCHER_AWS] Error during fpga_dma_burst_read.\n");
  }
  int ret = memcmp(source, check_buffer, size);
  free(check_buffer);
  return (ret == 0) ? FLETCHER_STATUS_OK : FLETCHER_STATUS_ERROR;
}

static fstatus_t check_slot_config(int slot_id) {

  // Parts of this function from AWS sources
  int rc = 0;
  struct fpga_mgmt_image_info info;

  // Check local image
  rc = fpga_mgmt_describe_local_image(slot_id, &info, 0);
  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] Unable to get local image information. Are you running as root?\n");
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

  // Check if slot is ready
  if (info.status != FPGA_STATUS_LOADED) {
    rc = 1;
    fprintf(stderr, "[FLETCHER_AWS] Slot %d is not ready.\n", slot_id);
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

  // Confirm that AFI is loaded
  if (info.spec.map[FPGA_APP_PF].vendor_id != AMZ_PCI_VENDOR_ID || 
      info.spec.map[FPGA_APP_PF].device_id != PCI_DEVICE_ID) {
    rc = 1;
    fprintf(stderr,
            "[FLETCHER_AWS] Slot appears loaded, but pci vendor or device ID doesn't match the expected value. \n"
            "\tYou may need to rescan the fpga with:\n"
            "\tfpga-describe-local-image -S  %d -R\n"
            "\tNote that rescanning can change which device file in /dev/ a FPGA will map to. "
            "\tTo remove and re-add your xdma driver and reset the device file mappings, run\n"
            "\t`sudo rmmod xdma && sudo insmod <aws-fpga>/sdk/linux_kernel_drivers/xdma/xdma.ko`\n"
            "\tThe PCI vendor id and device of the loaded image are not the expected values.", slot_id);
    return FLETCHER_STATUS_ERROR;
  }
  
    char dbdf[16];
    snprintf(dbdf,
                  sizeof(dbdf),
                  PCI_DEV_FMT,
                  info.spec.map[FPGA_APP_PF].domain,
                  info.spec.map[FPGA_APP_PF].bus,
                  info.spec.map[FPGA_APP_PF].dev,
                  info.spec.map[FPGA_APP_PF].func);
    debug_print("[FLETCHER_AWS] Operating on slot %d with id: %s", slot_id, dbdf);

  return FLETCHER_STATUS_OK;
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

  AwsConfig *config = NULL;

  if (arg != NULL) {
    config = (AwsConfig *) arg;
  } else {
    config = &aws_default_config;
  }

  aws_state.config = *config;

  debug_print("[FLETCHER_AWS] Initializing platform.       Arguments @ [host] %016lX.\n", (unsigned long) arg);

  int rc = fpga_mgmt_init();

  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] Cannot initialize FPGA management library.\n");
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

  rc = check_slot_config(config->slot_id);
  if (rc != FLETCHER_STATUS_OK) {
    fprintf(stderr, "[FLETCHER_AWS] Slot config is not correct.\n");
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

  // Open files for all queues
  for (int q = 0; q < FLETCHER_AWS_NUM_QUEUES; q++) {
    // Get the XDMA device filename

    // Attempt to open a XDMA DMA Queue
    debug_print("[FLETCHER_AWS] Attempting to open DMA queue %d.\n", q);
    
    aws_state.xdma_wr_fd[q] = fpga_dma_open_queue(FPGA_DMA_XDMA, aws_state.config.slot_id,
        /*channel*/ q, /*is_read*/ false);
    aws_state.xdma_rd_fd[q] = fpga_dma_open_queue(FPGA_DMA_XDMA, aws_state.config.slot_id,
        /*channel*/ q, /*is_read*/ true);

    if ((aws_state.xdma_rd_fd[q] < 0) || (aws_state.xdma_wr_fd[q] < 0)) {
      fprintf(stderr, "[FLETCHER_AWS] Did not get a valid file descriptor.\n"
                      "[FLETCHER_AWS] Is the XDMA driver installed?\n");
      aws_state.error = 1;
      return FLETCHER_STATUS_ERROR;
    }
  }

  // Set the PCI bar handle init
  aws_state.pci_bar_handle = PCI_BAR_HANDLE_INIT;
  debug_print("[FLETCHER_AWS] Bar handle init: %d\n", aws_state.pci_bar_handle);

  // Attach the FPGA
  debug_print("[FLETCHER_AWS] Attaching PCI <-> FPGA\n");
  rc = fpga_pci_attach(aws_state.config.slot_id,
                       aws_state.config.pf_id,
                       aws_state.config.bar_id,
                       0, //fpga_attach_flags
                       &aws_state.pci_bar_handle);

  debug_print("[FLETCHER_AWS] Bar handle init: %d\n", aws_state.pci_bar_handle);

  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] Could not attach PCI <-> FPGA. Are you running as root? "
                    "[FLETCHER_AWS] Entering error state. fpga_pci_attach: %d\n", rc);
    return FLETCHER_STATUS_ERROR;
  }

  return FLETCHER_STATUS_OK;
}

fstatus_t platformWriteMMIO(uint64_t offset, uint32_t value) {
  int rc = 0;
  rc = fpga_pci_poke(aws_state.pci_bar_handle, sizeof(uint32_t) * offset, value);
  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] MMIO write failed.\n");
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }
  debug_print("[FLETCHER_AWS] MMIO Write %d : %08X\n", (uint32_t) offset, (uint32_t) value);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformReadMMIO(uint64_t offset, uint32_t *value) {
  *value = 0xDEADBEEF;
  int rc = 0;
  rc = fpga_pci_peek(aws_state.pci_bar_handle, sizeof(uint32_t) * offset, value);
  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] MMIO read failed.\n");
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }
  debug_print("[FLETCHER_AWS] MMIO Read %d : %08X\n", (uint32_t) offset, (uint32_t)(*value));
  return FLETCHER_STATUS_OK;
}

fstatus_t platformCopyHostToDevice(const uint8_t *host_source, da_t device_destination, int64_t size) {
  size_t total = 0;

  debug_print("[FLETCHER_AWS] Copying host to device %016lX -> %016lX (%li bytes).\n",
              (uint64_t) host_source,
              (uint64_t) device_destination,
              size);

/*
 * use only 1 queue for now, the burst library functions take care of
 * issueing multiple DMA transfers.
 */  
  int q = 0; 
  ssize_t rc = 0;
  rc = fpga_dma_burst_write(aws_state.xdma_wr_fd[q], (uint8_t*)host_source, size, device_destination);
  if (rc < 0) {
    fprintf(stderr, "[FLETCHER_AWS] Copy host to device failed. Queue: %d.\n", q);
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

#ifdef DEBUG
  fstatus_t ddr_check = check_ddr(host_source, device_destination, size);
  if (ddr_check != FLETCHER_STATUS_OK) {
    fprintf(stderr, "[FLETCHER_AWS] Copied buffer in DDR differs from host buffer.\n");
  }
  return ddr_check;
#endif

  return FLETCHER_STATUS_OK;
}

fstatus_t platformCopyDeviceToHost(da_t device_source, uint8_t *host_destination, int64_t size) {
  size_t total = 0;

  debug_print("[FLETCHER_AWS] Copying device to host %016lX -> %016lX (%li bytes).\n",
              (uint64_t) device_source,
              (uint64_t) host_destination,
              size);

/*
 * use only 1 queue for now, the burst library functions take care of
 * issueing multiple DMA transfers.
 */  
  int q = 0; 
  ssize_t rc = 0;
  rc = fpga_dma_burst_read(aws_state.xdma_rd_fd[0], host_destination, size, device_source);
  if (rc < 0) {
    fprintf(stderr, "[FLETCHER_AWS] Copy device to host failed. Queue: %d.\n", q);
    aws_state.error = 1;
    return FLETCHER_STATUS_ERROR;
  }

  return FLETCHER_STATUS_OK;
}

fstatus_t platformTerminate(void *arg) {
  debug_print("[FLETCHER_AWS] Terminating platform.        Arguments @ [host] 0x%016lX.\n", (uint64_t) arg);

  int rc = fpga_pci_detach(aws_state.pci_bar_handle);

  if (rc != 0) {
    fprintf(stderr, "[FLETCHER_AWS] Could not detach FPGA PCI\n");
    return FLETCHER_STATUS_ERROR;
  }
  
  for (int q = 0; q < FLETCHER_AWS_NUM_QUEUES; q++) {
    close(aws_state.xdma_rd_fd[q]);
    close(aws_state.xdma_wr_fd[q]);
  }

  return FLETCHER_STATUS_OK;
}

fstatus_t platformDeviceMalloc(da_t *device_address, int64_t size) {
  *device_address = aws_state.buffer_ptr;
  debug_print("[FLETCHER_AWS] Allocating device memory.    [device] 0x%016lX (%10lu bytes).\n",
              (uint64_t) aws_state.buffer_ptr,
              size);
  aws_state.buffer_ptr += size + FLETCHER_AWS_DEVICE_ALIGNMENT - (size % FLETCHER_AWS_DEVICE_ALIGNMENT);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformDeviceFree(da_t device_address) {
  debug_print("[FLETCHER_AWS] Freeing device memory.       [device] 0x%016lX : NOT IMPLEMENTED.\n", device_address);
  return FLETCHER_STATUS_OK;
}

fstatus_t platformPrepareHostBuffer(const uint8_t *host_source, da_t *device_destination, int64_t size, int *alloced) {
  debug_print("[FLETCHER_AWS] Prepare is equal to cache on AWS f1.\n");
  *alloced = 1;
  return platformCacheHostBuffer(host_source, device_destination, size);
}

fstatus_t platformCacheHostBuffer(const uint8_t *host_source, da_t *device_destination, int64_t size) {
  *device_destination = aws_state.buffer_ptr;
  debug_print("[FLETCHER_AWS] Caching buffer on device.    [host] 0x%016lX --> 0x%016lX (%10lu bytes).\n",
              (unsigned long) host_source,
              (unsigned long) *device_destination,
              size);
  fstatus_t ret = platformCopyHostToDevice(host_source, aws_state.buffer_ptr, size);
  *device_destination = aws_state.buffer_ptr;
  aws_state.buffer_ptr += size + (FLETCHER_AWS_DEVICE_ALIGNMENT - (size % FLETCHER_AWS_DEVICE_ALIGNMENT));
  return ret;
}
