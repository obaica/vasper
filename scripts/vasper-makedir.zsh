#!/usr/bin/zsh

###############################################################################
# make various directories
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file makes various directories.

  Options:

    -h evoke function usage

    --raw_data      make raw_data directory
        \$1: abs path to POSCAR
        \$2: tolerance parse to phonopy, 1e-5 is phonopy default

    --relax_rough   make relax_rough directory
        read raw_data directory automatically
        EDIFF=1e-6, EDIFF=1e-4

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : Unexpected argments were parsed.

EOF
}

### constants
THIS_FILE=`which $0`
VASPER_DIR=$(dirname $(dirname $THIS_FILE))
MODULE_DIR=$VASPER_DIR/vasper

### error codes
source $MODULE_DIR/error-codes.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -raw_data

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--raw_data]}" ]]; then
  ##### $1: abs path to POSCAR
  ##### $2: tolerance parse to phonopy
  argnum_check "2" "$#"
  file_exists_check "raw_data"
  mkdir raw_data
  cp $1 raw_data
  cd raw_data
  phonopy --symmetry -c="$1" --tolerance="$2"
  echo "# phonopy symmetry" > "vasper.log"
  echo "phonopy --symmetry -c=$1 --tolerance=$2" >> "vasper.log"
  cd -
  exit 0
fi
