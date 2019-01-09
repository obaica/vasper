#!/usr/bin/zsh

###############################################################################
# auto run
###############################################################################

### usage
function usage()
{
  cat <<EOF
  auto run

  Options:

    -h evoke function usage

    --alm      run ALM calculation automatically
        \$1: vasper_alm_auto.conf file

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
           -alm

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--alm]}" ]]; then
  ##### $1: alm_auto.conf file
  if [ ! -e "calc0" ]; then
    uncorrect_directory `pwd`
  fi
  $VASPER_DIR/auto/alm.zsh "$1" | tee -a "vasper_alm_auto.log"
  exit 0
fi

nothing_excuted
