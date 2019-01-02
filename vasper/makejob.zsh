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

function lobster_command()
{
  echo "$LOBSTER"
}

function static_calc()
{
    vasprun_command
    echo 'mv INCAR INCAR_first'
    echo 'mv OUTCAR OUTCAR_first'
    echo 'mv vasprun.xml vasprun.xml_first'
    echo 'echo ""'
    echo 'echo "~~ revise INCAR ~~"'
    echo 'echo "before :"'
    echo 'cat INCAR_first'
    echo 'sed s/"# ICHARG = 11"/"ICHARG = 11"/g INCAR_first > INCAR'
    echo 'echo "after :"'
    echo 'cat INCAR'
    echo 'echo ""'
    echo 'echo "rerun VASP"'
    vasprun_command
}

function get_jobname_from_file()
{
  ##### $1: jobfile
  cat $1 | grep "#$ -N" | sed s/"#$ -N "/""/g
}
