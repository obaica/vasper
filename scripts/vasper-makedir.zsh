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

    --relax         make relax directory
        \$1: relax conf file

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

### modules
source $MODULE_DIR/error-codes.zsh
source $MODULE_DIR/conf.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -raw_data -relax

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--raw_data]}" ]]; then
  ##### $1: abs path to POSCAR
  ##### $2: tolerance parse to phonopy
  argnum_check "2" "$#"
  file_does_not_exist "raw_data"
  mkdir raw_data
  cp $1 raw_data
  cd raw_data
  phonopy --symmetry -c="$1" --tolerance="$2"
  echo "# phonopy symmetry" > "vasper.log"
  echo "phonopy --symmetry -c=$1 --tolerance=$2" >> "vasper.log"
  cd -
  exit 0
fi

if [[ -n "${opthash[(i)--relax]}" ]]; then
  ##### $1: relax conf file
  argnum_check "1" "$#"
  set_param_from_conf "$3"
  file_does_not_exist "$P_DIRNAME"
  mkdir $1
  cp $2 $3 $1
  cd $1
    vasper-makefile.zsh --job "vasp" "$P_DIRNAME"
    vasper-makefile.zsh --potcar "default" "PBE"
    vasper-makefile.zsh --kpoints "Monkhorst" "6 6 6" "0 0 0"
    vasper-makefile.zsh --incar_relax "1.3" "PBEsol"
  cd -
  exit 0
fi

nothing_excuted
