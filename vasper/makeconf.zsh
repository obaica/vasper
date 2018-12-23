#!/usr/bin/zsh

###############################################################################
# functions for making job.sh file
###############################################################################

### constant values
VASPER_DIR=$(dirname  $(dirname `which $0`))
TEMPLATE_DIR="$VASPER_DIR/template"

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
