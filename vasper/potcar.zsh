#!/usr/bin/zsh

###############################################################################
# functions for making POTCAR file
###############################################################################

### constant values
VASPER_DIR=$(dirname  $(dirname `which $0`))
TEMPLATE_DIR="$VASPER_DIR/template"
PROFILE=$HOME/.vasperrc
POT_DIR=`cat $PROFILE | grep "POT_DIR = " | sed s/"POT_DIR = "/""/g`
DEFAULT_POTCAR="$TEMPLATE_DIR/default_potcar.txt"

### functions
function get_enmax_from_potcar()
{
  ##### $1: POTCAR file
  ### extract ENMAX from POTCAR
  ENMAX_LST=()
  ENMAX_LINE=(`grep -n ENMAX $1 | sed -e 's/:.*//g'`)
  for i in $ENMAX_LINE
  do LINE=(`sed -n ${i}p $1`)
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

function make_default_potcar_from_elements()
{
  ##### $1 : element names, ex. "Na Cl"
  ##### $2 : LDA or PBE
  ELES=(`echo $1`)
  touch POTCAR
  echo "POTCAR database directory : $POT_DIR"
  for i in $ELES
  do
    POT_F_NAME=`cat $TEMPLATE_DIR/default_potcar.txt |
                grep -v "#" |
                grep "${i}" |
                grep -v "${i}[a-zA-Z]"`_${2}
    if [ -e $POT_DIR/$POT_F_NAME ]; then
      echo "writing $POT_F_NAME to POTCAR"
      cat $POT_DIR/$POT_F_NAME >> POTCAR
    else
      echo "$POT_DIR/$POT_F_NAME does not exist"
      rm -f POTCAR
      echo "exit(252)"
      exit 252
    fi
  done
}

function make_default_potcar_from_poscar()
{
  ##### $1 : POSCAR file
  ##### $2 : LDA or PBE
  echo "reading $1 file"
  POS_LINE6=`sed -n 6p $1`
  make_default_potcar_from_elements $POS_LINE6 $2
}
