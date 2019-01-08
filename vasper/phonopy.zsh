#!/usr/bin/zsh
set -e

###############################################################################
# functions for phonopy and phono3py
###############################################################################

function make_disp_files()
{
  ##### $1: 'fc2' or 'fc3' or 'alm'
  ##### $2: conf file
  ##### $3: FORCE_SETS file path
  if [ "$1" = "fc2" ]; then
    phonopy $2
  elif [ "$1" = "fc3" ]; then
    phono3py $2
  elif [ "$1" = "alm" ]; then
    DIM="`cat disp_alm.conf | grep DIM | sed s/"DIM = "/""/g`"
    TEMP="`cat disp_alm.conf | grep TEMPERATURE | sed s/"TEMPERATURE = "/""/g`"
    DISP_NUM="`cat disp_alm.conf | grep DISP_NUM | sed s/"DISP_NUM = "/""/g`"
    FORCE_SETS="$3"
    # source /home/mizokami-ubuntu/.pyenv/versions/anaconda3-5.3.1/etc/profile.d/conda.sh
    conda activate $ALM_ENV
    $MODULE_DIR/alm-phonopy.py -d --dim=$DIM --temperature=$TEMP --num=$DISP_NUM --fs=$FORCE_SETS
    conda deactivate
  else
    {
      echo "you specified '$1' = $1"
      echo "'$1' must be 'fc2' or 'fc3' or 'alm'"
      unexpected_args "$1"
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
    unexpected_args "$#num"
  fi
}

### make disp directories
function make_disp_dirs()
{
  ##### $1: filetype 'fc2' 'fc3' 'alm'
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
    cp -r POTCAR disp-${num}/POTCAR
    cp -r KPOINTS disp-${num}/KPOINTS
    cp -r INCAR disp-${num}/INCAR
    cat job_${1}.sh | sed s/"${1}"/"${1}_${num}"/g > disp-${num}/job_${1}.sh
    mv $i disp-${num}/POSCAR
  done
}

### get dirname for creating alm calculation
function get_alm_dirname()
{
  ##### $1 : 'next' or 'last'
  COUNT=1
  while [ -e "calc${COUNT}" ]
  do
    COUNT=`expr $COUNT + 1`
  done
  if [ "$1" = "next" ]; then
    echo calc${COUNT}
  elif [ "$1" = "last" ]; then
    # COUNT=`expr $COUNT - 1`
    echo calc$((${COUNT}-1))
  else
    unexpected_args "$1"
  fi
}
