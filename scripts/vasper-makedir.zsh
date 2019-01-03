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

    --band          make band directory
        \$1: relax dirname
        \$2: new directory name

    --dos           make dos directory
        \$1: relax dirname
        \$2: new directory name

    --lobster       make lobster directory
        \$1: relax dirname
        \$2: new directory name
        \$3: calculate n th neighbor atoms ex. "2"

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
zparseopts -D -A opthash -- h -band -dos -lobster -raw_data -relax

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--band]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"band"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR in $1 to $2"
  mkdir $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "makeing job_dos.sh"
  vasper-makefile.zsh --job "band" "$JOBNAME"
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints "band" "100" "POSCAR"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_band "INCAR"
  exit 0
fi

if [[ -n "${opthash[(i)--dos]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"dos"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $1 to $2"
  mkdir $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $1/KPOINTS $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "makeing job_dos.sh"
  vasper-makefile.zsh --job "dos" "$JOBNAME"
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_multi "KPOINTS" "2"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_dos "INCAR"
  exit 0
fi

if [[ -n "${opthash[(i)--lobster]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  ##### $3: calculate n th neighbor atoms ex. "2"
  argnum_check "3" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"lobster"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $1 to $2"
  mkdir $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $1/KPOINTS $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "making job_lobster.sh"
  vasper-makefile.zsh --job "lobster" "$JOBNAME"
  echo ""
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_multi "KPOINTS" "2"
  echo ""
  echo "revising INCAR"
  vasper-makefile.zsh --incar_lobster "INCAR" "$RELAX_DIR/vasprun.xml" "POSCAR" "POTCAR"
  echo ""
  echo "making lobsterin"
  vasper-makefile.zsh --lobsterin "POSCAR" "POTCAR" "$3"
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
  touch "vasper.log"
  echo "making $P_DIRNAME directory" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  mkdir $P_DIRNAME
  echo "coping POSFILE in  $P_DIRNAME directory" | tee -a "vasper.log"
  echo "POSCAR file : `pwd`/$P_POSFILE"
  echo "" | tee -a "vasper.log"
  cp $1 $P_DIRNAME
  cp $P_POSFILE $P_DIRNAME/POSCAR
  mv "vasper.log" $P_DIRNAME
  cd $P_DIRNAME
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
  if [ "$P_KSAMP_METHOD" = "auto" ]; then
    echo "read bravais lattice, 'P_KSHIFT' setting will be ignored" | tee -a "vasper.log"
    vasper-makefile.zsh --kpoints "$P_KSAMP_METHOD" "$P_KNUM" "POSCAR"
  else
    vasper-makefile.zsh --kpoints "$P_KSAMP_METHOD" "$P_KNUM" "$P_KSHIFT"
  fi
  echo "" | tee -a "vasper.log"
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
