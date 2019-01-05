#!/usr/bin/zsh
set -e

###############################################################################
# set up vasp calculation for phonon
###############################################################################

### usage
function usage()
{
  cat <<EOF
  this script is a tool for phonon calculation against id-xxxxxx compound

  Options:
    -h          print usage

    --fc2       make fc2 directory and make displacements
        \$1: jobname header

    --alm       make alm directory
        \$1: jobname header
        \$2: dimension ex) '2 2 2'
        \$3: sampling number
        \$4: temperature

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : Some needed files for running specific modes do not exist.
    252 : Unexpected argments were parsed
EOF
}

### constants
PHONALY_DIR=$(dirname  $(dirname `which $0`))
PROFILE=${PHONALY_DIR}/phonaly_profile
SETUP_CALC_FILE=${PHONALY_DIR}/phonaly/setup_calc.zsh

### source
source $SETUP_CALC_FILE

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
zparseopts -D -A opthash -- h -fc2 -alm

if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--fc2]}" ]]; then
  ##### $1: jobname header
  argnum_check "1" "$#"
  file_exist "vasp"
  file_exist "disp_fc2"
  make_disp_files "fc2"
  make_disp_dirs "$1"
  exit 0
fi

if [[ -n "${opthash[(i)--alm]}" ]]; then
  ##### $1: jobname header
  ##### $2: dimension ex) '2 2 2'
  ##### $3: sampling number
  ##### $4: temperature
  # activate alm
  echo "activating alm environment"
  `cat $PROFILE | grep "ACT_ALM_ENV" | sed s/"ACT_ALM_ENV = "/""/g`
  echo `cat $PROFILE | grep "ACT_ALM_ENV" | sed s/"ACT_ALM_ENV = "/""/g`
  argnum_check "4" "$#"
  file_exist "vasp"
  make_disp_files "alm" "$2" "$3" "$4"
  make_disp_dirs "$1"
  echo "deactivating alm environment"
  `cat $PROFILE | grep "DEAC_ALM_ENV" | sed s/"DEAC_ALM_ENV = "/""/g`
  exit 0
fi

nothing_excuted
