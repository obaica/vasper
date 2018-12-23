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
source $MODULE_DIR/incar.zsh

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
  file_does_not_exist_check "raw_data"
  mkdir raw_data
  cp $1 raw_data
  cd raw_data
  phonopy --symmetry -c="$1" --tolerance="$2"
  touch "vasper.log"
  echo "# phonopy symmetry" | tee "vasper.log"
  echo "phonopy --symmetry -c=$1 --tolerance=$2" | tee "vasper.log"
  cd -
  exit 0
fi

if [[ -n "${opthash[(i)--relax]}" ]]; then
  ##### $1: relax conf file
  argnum_check "1" "$#"
  source $1
  file_exists_check "$P_POSFILE"
  file_does_not_exist_check "$P_DIRNAME"
  echo "making $P_DIRNAME directory"
  echo ""
  mkdir $P_DIRNAME
  cp $1 $P_POSFILE $P_DIRNAME
  cd $P_DIRNAME
  touch "vasper.log"
  echo "~~ making job_relax.sh ~~" | tee -a "vasper.log"
  echo "job name : $P_JOBNAME" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  vasper-makefile.zsh --job "relax" "$P_JOBNAME"
  echo "~~ making POTCAR ~~" | tee -a "vasper.log"
  echo "psudopotential : $P_PSP" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  vasper-makefile.zsh --potcar "default" "$P_PSP"
  echo "~~ making KPOINTS ~~" | tee -a "vasper.log"
  echo "sampling method : $P_KSAMP_METHOD" | tee -a "vasper.log"
  echo "sampling num : $P_KNUM" | tee -a "vasper.log"
  echo "shift : $P_KSHIFT" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  vasper-makefile.zsh --kpoints "$P_KSAMP_METHOD" "$P_KNUM" "$P_KSHIFT"
  echo "~~ making INCAR ~~" | tee -a "vasper.log"
  echo "ENCUT : $P_ENCUT" | tee -a "vasper.log"
  echo "EDIFF : $P_EDIFF" | tee -a "vasper.log"
  echo "EDIFFG : $P_EDIFFG" | tee -a "vasper.log"
  vasper-makefile.zsh --incar_relax "$P_ENCUT" "$P_PSP"
  revise_incar_param "INCAR" "EDIFF" "$P_EDIFF"
  revise_incar_param "INCAR" "EDIFFG" "$P_EDIFFG"
  cd -
  exit 0
fi

nothing_excuted
