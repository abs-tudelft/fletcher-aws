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

#ifndef FLETCHER_AWS_SIM_H
#define FLETCHER_AWS_SIM_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Configuration structure that can be assigned to
 * fletcher::Platform::init_data.
 */
typedef struct {

  /**
   * The index of the DDR bank to use for buffer allocations (0=A, 1=B, 2=C,
   * 3=D). If you set this to a bank that isn't actually synthesized in the
   * design, DMA transfers will lock up and a hard reset is required. This is
   * set to 2 (bank C) by default as it should always exist. Note that you can
   * always manually transfer buffers to any bank, this is just for automatic
   * buffer allocation.
   */
  int ddr_bank;

} InitOptions;

/**
 * Default configuration for the above, used when the configuration structure
 * pointer is null/not specified.
 */
#define FLETCHER_AWS_SIM_CONFIG_DEFAULT {2}

#ifdef __cplusplus
}
#endif

#endif
