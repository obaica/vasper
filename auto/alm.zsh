#!/usr/bin/zsh

##### $1 : alm_auto.conf file

### source
source $HOME/.vasperrc
source $MODULE_DIR/qsystem.zsh

### dirnames
BASE_DIR=`pwd`
PHONOPY_DIR=$BASE_DIR/phonopy

### read alm_auto.conf
MESH=`cat "$1" | sed s/"MESH = "/""/g`
MESH_NO_SPACE=`echo "$MESH" | sed s/" "/""/g`
DOS_CONF=dos-m${MESH_NO_SPACE}.conf

### functions
function phonopy_working()
{
  ##### $1 : number
  cd $PHONOPY_DIR
  phonopy $DOS_CONF
  mkdir -p force_sets mesh
  mv mesh.hdf5 mesh/calc{$1}_mesh.hdf5
  mv FORCE_SETS force_sets/calc{$1}_FORCE_SETS
  cd $BASE_DIR
}


### phonopy directory
mkdir -p $PHONOPY_DIR
vasper-makefile.zsh --get_conf "dos" "disp_alm.conf" "$MESH"
mv $DOS_CONF $PHONOPY_DIR
cp "BORN" "POSCAR-unitcell" "calc0/FORCE_SETS" $PHONOPY_DIR
phonopy_working "0"



### alm calculation
vasper-makedir.zsh --disp "disp_alm.conf"
cd `ls | grep calc | sort | tail -n 1`
vasper-qsub.zsh --disp "alm"
# sleep 10
# JOB_IDS=(`tail -n +2 "vasper_job.log" | cut -d " " -f 1`)
# ALL_JOBS=`revised_qstat | cut -d " " -f 1`
# 
# 
# 
# vasper-makefile.zsh --force_sets "alm"
# cp FORCE_SETS $PHONOPY_DIR
# cd $PHONOPY_DIR
