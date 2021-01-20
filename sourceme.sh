script=${BASH_SOURCE[0]}
if [ $script == $0 ]; then
  echo "ERROR: You must source this script"
  exit 2
fi

full_script=$(readlink -f $script)
fletcher_aws_dir=$(dirname $full_script)


export FLETCHER_AWS_DIR=$fletcher_aws_dir

#clone subrepos if they haven't been already
git submodule init
git submodule update

source $fletcher_aws_dir/aws-fpga/sdk_setup.sh
source $fletcher_aws_dir/aws-fpga/hdk_setup.sh
