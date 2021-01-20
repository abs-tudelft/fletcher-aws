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

INCLUDES = -I$(SDK_DIR)/userspace/include -I$(FLETCHER_AWS_DIR)/runtime/runtime/src

CC = g++
CPPFLAGS = -DCONFIG_LOGLEVEL=4 -g -Wall -Werror $(INCLUDES)

#the -L library include directories are only needed if the platform libraries are not installed
LDLIBS = -L$(FLETCHER_AWS_DIR)/runtime/runtime/build -lfpga_mgmt -lfletcher -lfletcher_aws

SRC = tidre.cpp
OBJ = $(SRC:.cpp=.o)


all: tidre check_env $(BIN)

tidre: $(OBJ)
	$(CC) $(CFLAGS) -o tidre tidre.o $(LDFLAGS) $(LDLIBS)

clean:
	rm -f *.o tidre

check_env:
ifndef SDK_DIR
	$(error SDK_DIR is undefined. Try "source sdk_setup.sh" to set the software environment)
endif
ifndef FLETCHER_AWS_DIR
	$(error Environment variable FLETCHER_AWS_DIR not set. please source fletcher-aws sourceme.sh)
endif

