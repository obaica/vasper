#!/usr/bin/zsh

###############################################################################
# functions for making job.sh file
###############################################################################

function job_header()
{
  ##### $1: jobname
  cat $TEMPLATE_DIR/qsystem-header | sed s/"jobname"/"$1"/g
}

function vasprun_command()
{
  echo "$MPIRUN $VASP"
}
