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

    --incar_relax   make INCAR for relax
        if ENCUT is less than 10, automatically read 'POTCAR' \
        for extructing ENMAX and ENCUT=ENMAX*$1
        \$1: ENCUT
        \$2: GGA, ex. "PBEsol"

    --job           make job.sh
        \$1: run mode 'vasp'
        \$2: jobname

    --kpoints       make KPOINTS
        \$1: run mode 'Monkhorst' or 'Gamma' or 'band'
        \$2: kpoints 'Monkhorst' or 'Gamma' , ex. "6 6 6"
                     'band' , ex. 100
        \$3: 'Monkhorst' or 'Gamma' => shift, ex. "0 0 0"
             'band' => posfile, ex. "POSCAR"

    --potcar        make job.sh
        automatically read POSCAR to extract elements used
        \$1: run mode 'default'
        \$2: psp "LDA" or "PBE"


  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : unexpected argments were parsed

EOF
}

### constants
THIS_FILE=`which $0`
VASPER_DIR=$(dirname $(dirname $THIS_FILE))
MODULE_DIR=$VASPER_DIR/vasper

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

### check file exists
function file_exists_check()
{
  ##### $1: check filename
  if [ -e "$1" ]; then
    echo "file exists : $1"
      echo "exit(253)"
    exit 253
  fi
}

### check file does not exist
function file_does_not_exist_check()
{
  ##### $1: check filename
  if [ ! -e "$1" ]; then
    echo "file does not exist : $1"
    echo "exit(252)"
    exit 252
  fi
}

### check keys of args
function unexpected_args()
{
  ##### $1: unexpected_argment
  echo "unexpected argments parsed : $1"
  echo "exit(251)"
  exit 251
}

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -incar_relax -job -kpoints \
           -potcar

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--incar_relax]}" ]]; then
   ##### $1: ENCUT
   ##### $2: GGA, if "PBEsol" then GGA = PS
  source $MODULE_DIR/incar.zsh
  argnum_check "2" "$#"
  file_exists_check "INCAR"
  file_does_not_exist_check "POTCAR"
  mk_incar_relax "$1" "$2"
  exit 0
fi

if [[ -n "${opthash[(i)--job]}" ]]; then
  ##### $1: run mode
  ##### $2: jobname
  source $MODULE_DIR/makejob.zsh
  argnum_check "2" "$#"
  file_exists_check "job.sh"
  job_header $2 > "job.sh"
  echo ""
  if [ "$1" = "vasp" ]; then
    vasprun_command >> "job.sh"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--kpoints]}" ]]; then
  ##### $1: run mode 'Monkhorst' or 'Gamma' or 'band'
  ##### $2: kpoints 'Monkhorst' or 'Gamma' , ex. "6 6 6"
  #####             'band' , ex. 100
  ##### $3: 'Monkhorst' or 'Gamma' => shift, ex. "0 0 0"
  #####     'band' => posfile, ex. "POSCAR"
  argnum_check "3" "$#"
  file_exists_check "KPOINTS"
  if [ "$1" = "band" ]; then
    $MODULE_DIR/kpoints.py --style="$1" --knum="$2" -c="$3"
  else
    $MODULE_DIR/kpoints.py --style="$1" --kpts="$2" --shift="$3"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--potcar]}" ]]; then
  ##### $1: run mode "default"
  ##### $2: psp "LDA" or "PBE"
  argnum_check "2" "$#"
  file_exists_check "POTCAR"
  file_does_not_exist_check "POSCAR"
  source $MODULE_DIR/potcar.zsh
  if [ "$1" = "default" ]; then
    make_default_potcar_from_poscar "POSCAR" "$2"
    if [ "$?" = "252" ]; then
      exit 252
    fi
  else
    unexpected_args "$1"
  fi
  exit 0
fi

nothing_excuted
