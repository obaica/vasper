#!/usr/bin/zsh

###############################################################################
# make various files used in VASP calculation
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file makes various files used in VASP calculation.

  Options:

    -h evoke function usage

    --job           cat various job.sh
        \$1: run mode 'fc2'
        \$2: jobname

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    252 : Unexpected argments were parsed

EOF
}

### constants
VASPER_MAKEFILE_FILE=`which $0`
MAKEFILE_FILE=$(dirname $(dirname $VASPER_MAKEFILE_FILE))/vasper/makefile.zsh

### source
source $MAKEFILE_FILE

### nothing was excuted
function nothing_excuted()
{
  {
    echo "nothing was excuted"
    echo "please check usage : $(basename ${0}) -h"
    echo "exit(255)"
    exit 255
  }
}

### check the number of argments
function argnum_check()
{
  ##### $1: expected argments number
  ##### $2: actual argments number
  if [ "$1" != "$2" ]; then
    {
      echo "The number of argments is different from expected."
      echo "expected argment number : $1"
      echo "actual argment number : $2"
      echo "exit(254)"
      exit 254
    }
  fi
}

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -job

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--job]}" ]]; then
  ##### $1: run mode
  ##### $2: jobname
  argnum_check "2" "$#"
  job_header $2
  echo ""
  if [ "$1" = 'fc2' ]; then
    vasprun_command
  fi
  exit 0
fi

nothing_excuted
