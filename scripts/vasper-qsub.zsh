#!/usr/bin/zsh

###############################################################################
# make various files used in VASP calculation
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file provides advantage qsub functions

  Options:

    -h evoke function usage

    --disp         make displaced files
        \$1: 'fc2' 'alm'
        \$2: que name (option) ex. "vega-e"
  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : Unexpected argments were parsed.
    250 : You tried to run in the uncorrect directory.

EOF
}

### envs
source $HOME/.vasperrc

### error codes
source $MODULE_DIR/error-codes.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h \
           -disp \

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--disp]}" ]]; then
  ##### $1: 'fc2' 'alm'
  ##### $2: que name (option) ex. "vega-e"
  source $MODULE_DIR/qsystem.zsh
  if [ "`ls | grep disp-0 | wc -l`" = "0" ]; then
    echo "could not find any disp-**** directory"
    uncorrect_directory `pwd`
  fi

  if [ "$1" = "alm" ]; then
    disp_qsub "job_alm.sh" "$2"
  if [ "$1" = "fc2" ]; then
    disp_qsub "job_fc2.sh" "$2"
  else
    unexpected_args "$1"
  fi
  exit 0
fi

nothing_excuted
