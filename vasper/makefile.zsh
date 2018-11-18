#!/usr/bin/zsh

###############################################################################
# functions for making various files used in VASP calculation
###############################################################################

### constants
VASPER_DIR=$(dirname  $(dirname `which $0`))
TEMPLATE_DIR="$VASPER_DIR/template"
PROFILE=${VASPER_DIR}/vasper_profile

function job_header()
{
  ##### $1: jobname
  cat $TEMPLATE_DIR/qsystem-header | sed s/"jobname"/"$1"/g
}

function vasprun_command()
{
  local MPIRUN=`cat $PROFILE | grep "MPIRUN = " | sed s/"MPIRUN = "/""/g`
  local VASP=`cat $PROFILE | grep "VASP = " | sed s/"VASP = "/""/g`
  echo "$MPIRUN $VASP"
}
