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
        if ENCUT is less than 10, automatically read 'POTCAR' for extructing ENMAX and ENCUT=ENMAX*ENCUT
        \$1: ENCUT
        \$2: GGA, ex. "PBEsol"

    --job           make job.sh
        \$1: run mode 'relax'
        \$2: jobname

    --kpoints       make KPOINTS
        \$1: run mode 'Monkhorst' or 'Gamma' or 'band'
        \$2: kpoints 'Monkhorst' or 'Gamma' , ex. "6 6 6"
                     'band' , ex. 100
        \$3: 'Monkhorst' or 'Gamma' => shift, ex. "0 0 0"
             'band' => posfile, ex. "POSCAR"

    --potcar        make job.sh
        automatically read POSCAR to extract elements
        \$1: run mode 'default'
        \$2: psp "LDA" or "PBE" or "PBEsol"


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

### envs
source $HOME/.vasperrc

### error codes
source $MODULE_DIR/error-codes.zsh

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
  file_does_not_exist_check "INCAR"
  file_exists_check "POTCAR"
  mk_incar_relax "$1" "$2"
  exit 0
fi

if [[ -n "${opthash[(i)--job]}" ]]; then
  ##### $1: run mode
  ##### $2: jobname
  source $MODULE_DIR/makejob.zsh
  argnum_check "2" "$#"
  file_does_not_exist_check "job.sh"
  job_header $2 > "job.sh"
  echo ""
  if [ "$1" = "relax" ]; then
    vasprun_command >> "job_relax.sh"
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
  file_does_not_exist_check "KPOINTS"
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
  file_does_not_exist_check "POTCAR"
  file_exists_check "POSCAR"
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
