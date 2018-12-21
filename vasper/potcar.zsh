#!/usr/bin/zsh

###############################################################################
# functions for making POTCAR file
###############################################################################

function get_enmax_from_potcar
{
  ##### $1: POTCAR file
  ### extract ENMAX from POTCAR
  ENMAX_LST=()
  ENMAX_LINE=(`grep -n ENMAX $1 | sed -e 's/:.*//g'`)
  for i in $ENMAX_LINE
  do
    LINE=(`sed -n ${i}p $1`)
    ENMAX_LST=($ENMAX_LST `echo $LINE[3] | sed -e 's/;//g'`)
  done

  ### determine ENCUT
  MAX=0
  for i in $ENMAX_LST
  do
    if (($i > $MAX)) ;then
      MAX=$i
    fi
  done
  echo $MAX
}
