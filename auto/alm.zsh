#!/usr/bin/zsh

##### $1 : alm_auto.conf file

### check
if [ "$1" = "" ]; then
  echo "$1 is not set"
  exit 1
fi

### source
source $HOME/.vasperrc
source $MODULE_DIR/qsystem.zsh

### dirnames
BASE_DIR=`pwd`
PHONOPY_DIR=$BASE_DIR/phonopy

### read alm_auto.conf
MESH=`cat "$1" | grep "MESH = " | sed s/"MESH = "/""/g`
SLEEP_MINITES=`cat "$1" | grep "SLEEP_MINITES = " | sed s/"SLEEP_MINITES = "/""/g`
LOOP_NUM=`cat "$1" | grep "LOOP_NUM = " | sed s/"LOOP_NUM = "/""/g`
THRESHOLD=`cat "$1" | grep "THRESHOLD = " | sed s/"THRESHOLD = "/""/g`

MESH_NO_SPACE=`echo "$MESH" | sed s/" "/""/g`
DOS_CONF=dos-m${MESH_NO_SPACE}.conf

### functions
function phonopy_working()
{
  ##### $1 : number
  cd $PHONOPY_DIR
  phonopy $DOS_CONF --alm
  mkdir -p force_sets mesh
  mv mesh.hdf5 mesh/calc${1}_mesh.hdf5
  mv FORCE_SETS force_sets/calc${1}_FORCE_SETS
  cd $BASE_DIR
}

function check_finish()
{
  ALL_JOBS=`revised_qstat | cut -d " " -f 1`
  for i in $JOB_IDS
  do
    if `echo $ALL_JOBS | grep -q $i`; then
      return 1
    fi
    done
    return 0
}

function check_convergence()
{
  ##### $1 : number
  cd $PHONOPY_DIR
  MESH1=$PHONOPY_DIR/mesh/calc${1}_mesh.hdf5
  MESH2=$PHONOPY_DIR/mesh/calc$((${1}-1))_mesh.hdf5
  OUTPUT=`$MODULE_DIR/alm-phonopy.py -bd --mesh1="$MESH1" --mesh2="$MESH2"`
  D_FREC=`echo $OUTPUT | grep "average frequency difference" | rev | cut -d " " -f 1 | rev`
  if [ ! -e "alm_convergence.log" ]; then
    echo "calc average_difference_from_previous_step(THz)" > "alm_convergence.log"
  fi
  echo "calc${1} $D_FREC" >> "alm_convergence.log"
  cd $BASE_DIR

  if [ "$D_FREC" -lt "$THRESHOLD" ]; then
    echo "converged"
    return 0
  else
    echo "did not converge"
    return 1
  fi
}

### phonopy directory
if [ ! -e $PHONOPY_DIR ]; then
  mkdir -p $PHONOPY_DIR
  vasper-makefile.zsh --get_conf "dos" "disp_alm.conf" "$MESH"
  mv $DOS_CONF $PHONOPY_DIR
  cp "BORN" "POSCAR-unitcell" "calc0/FORCE_SETS" $PHONOPY_DIR
  phonopy_working "0"
fi

### alm calculation
for NUM in $LOOP_NUM
do
  ### make displacements and qsub
  vasper-makedir.zsh --disp "disp_alm.conf"
  CALC_DIR=$BASE_DIR/`ls | grep calc | sort | tail -n 1`
  CALC_DIR_NUM=`basename "$CALC_DIR" | sed -e 's/[^0-9]//g'`
  cd $CALC_DIR
  vasper-qsub.zsh --disp "alm"
  JOB_IDS=(`tail -n +2 "vasper_job.log" | cut -d " " -f 1`)

  ### check whethere jobs finish
  while ! `check_finish`
  do
    sleep $(($SLEEP_MINITES*60))
    echo "`date +"%Y/%m/%d/%I:%M:%S"` : jobs do not finished"
  done
  echo "`date +"%Y/%m/%d/%I:%M:%S"` : all jobs finish !"

  ### post process
  vasper-makefile.zsh --force_sets "alm"
  cp FORCE_SETS $PHONOPY_DIR
  phonopy_working $CALC_DIR_NUM
  check_convergence $CALC_DIR_NUM
  if [ "$?" = 0 ]; then
    exit 0
  fi
done

echo "reached maximum loop"
