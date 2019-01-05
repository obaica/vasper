#!/usr/bin/zsh
set -e

###############################################################################
# functions for setting up vasp calculation for phonon
###############################################################################

### constant values
CUR_DIR=`pwd`
PHONALY_DIR=$(dirname  $(dirname `which $0`))
PROFILE=${PHONALY_DIR}/phonaly_profile

### check whether files exist in the current directory
function file_exist()
{
  ##### $1: "vasp" <= check VASP files
  #####     "disp_fc2" <= check disp_fc2.conf
  #####     "disp_fc3" <= check disp_fc3.conf
  #####
  #####     Structure file name must be "POSCAR-unitcell" not "POSCAR"
  local VASP_FILENAMES=("INCAR" "KPOINTS" "POSCAR-unitcell" "POTCAR")
  local DISP_FC2_CONF_FILENAME=("disp_fc2.conf")
  local DISP_FC3_CONF_FILENAME=("disp_fc3.conf")

  if [ "$1" = "vasp" ]; then
    echo "--VASP files check--"
    local check_files=(`echo $VASP_FILENAMES`)
  elif [ "$1" = "disp_fc2" ]; then
    echo "--disp_fc2.conf check--"
    local check_files=$DISP_FC2_CONF_FILENAME
  elif [ "$1" = "disp_fc3" ]; then
    echo "--disp_fc3.conf check--"
    local check_files=$DISP_FC3_CONF_FILENAME
  else
      echo "you specified '$1' = $1"
      echo "'$1' must be 'vasp' or 'disp_fc2' or 'disp_fc3'"
      echo "exit(252)"
      exit 252
  fi

  for i in $check_files
  do
    if [ -e $i ]; then
      echo "$i : OK"
    else
      {
        echo "$i : FAIL!"
        echo "there is no $i in the current directory"
        echo "exit(253)"
        exit 253
      }
    fi
  done
  echo ""
}

### make displacements from disp conf file
function make_disp_files()
{
  ##### $1: "fc2" <= make fc2 displacements
  #####     "fc3" <= make fc3 displacements
  #####     "alm" <= sampling
  ##### $2: "dimension" ex) '2 2 2'
  ##### $3: sampling number (only if $1="alm")
  ##### $4: temperature (only if $1="alm")
  if [ "$1" = "fc2" ]; then
    phonopy disp_fc2.conf
  elif [ "$1" = "fc3" ]; then
    phono3py disp_fc3.conf
  elif [ "$1" = "alm" ]; then
    # PHONOPY_DIR=`cat $PROFILE | grep "PHONOPY_DIR" | sed s/"PHONOPY_DIR = "/""/g`
    # phonaly-alm.py --phonopy_path="$PHONOPY_DIR" --dim=$2 --num=$3 --temperature=$4
    phonaly-alm.py -d --dim=$2 --num=$3 --temperature=$4
  else
    {
      echo "you specified '$1' = $1"
      echo "'$1' must be 'fc2' or 'fc3'"
      echo "exit(252)"
      exit 252
    }
  fi
}

### specify fc2 or fc3 or alm from the filename of the displaced files
function _is_fc2_fc3_alm()
{
  ##### $1: disp POSCAR name  ex) POSCAR-00001
  local num=`echo $1 | sed -e "s/[^0-9]//g"`
  if [ $#num = 3 ]; then
    echo "fc2"
  elif [ $#num = 4 ]; then
    echo "alm"
  elif [ $#num = 5 ]; then
    echo "fc3"
  else
    echo "func _is_fc2_fc3_alm : unexpected error occured"
    exit 1
  fi
}

### make disp directories
function make_disp_dirs()
{
  ##### $1: jobname header
  local disp_poscars=(`find POSCAR-[0-9r]* | sort`)
  local run_mode=`_is_fc2_fc3_alm $disp_poscars[1]`
  {
    echo "run mode : $run_mode"
    echo "making disp-*** directories"
  }
  for i in $disp_poscars
  do
    local num=`echo $i | sed -e "s/[^0-9]//g"`
    mkdir disp-${num}
    cp -r $CUR_DIR/POTCAR $CUR_DIR/disp-${num}/POTCAR
    cp -r $CUR_DIR/KPOINTS $CUR_DIR/disp-${num}/KPOINTS
    cp -r $CUR_DIR/INCAR $CUR_DIR/disp-${num}/INCAR
    vasper-makefile.zsh --job "fc2" "${1}_${run_mode}_${num}" \
      >disp-${num}/job_${run_mode}.sh
    mv $i disp-${num}/POSCAR
  done
}
