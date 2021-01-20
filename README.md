# fletcher-aws

[![Build Status](https://dev.azure.com/abs-tudelft/fletcher/_apis/build/status/abs-tudelft.fletcher-aws?branchName=master)](https://dev.azure.com/abs-tudelft/fletcher/_build/latest?definitionId=7&branchName=master)

Fletcher AWS platform support.

To use, source `sourceme.sh` (this will also clone the subrepos and configure the aws-fpga environment)


Issues:
- By default we only instantiate 1 DDR controller. This can be changed easily by removing the `defines in the toplevel, but it would be nicer to make this more parameterized.
- cosim assumes only DIMM C will be used. To use other DIMMs, they need to be initialized and this takes a while. See init_DDR().
- cosim assumes the runtime has been built into the build directory. We should check and give an early error or automate this.
