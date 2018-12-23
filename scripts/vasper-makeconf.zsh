#!/usr/bin/zsh

###############################################################################
# make various conf file
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file makes various conf file.

  Options:

    -h evoke function usage

    --potcar        make job.sh
        automatically read POSCAR to extract elements
        \$1: run mode 'default'
        \$2: psp "LDA" or "PBE"


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
source $MODULE_DIR/makeconf.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--relax]}" ]]; then
   ##### $1: directory name
   ##### $2: jobname
  source $MODULE_DIR/incar.zsh
  argnum_check "2" "$#"
  file_exists_check "INCAR"
  file_does_not_exist_check "POTCAR"
  mk_incar_relax "$1" "$2"
  exit 0
fi

nothing_excuted
