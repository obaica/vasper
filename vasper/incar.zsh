#!/usr/bin/zsh

###############################################################################
# functions for making INCAR file
###############################################################################

### constants
INCAR_RELAX_SAMPLE="$TEMPLATE_DIR/INCAR_relax"

function mk_incar_relax()
{
  ##### $1: ENCUT "1.3" or "500"
  ##### $2: GGA  ex) "PBEsol" or ""
  ENCUT=`revise_encut $1`
  ENCUT_LINE=`grep -n ENCUT $INCAR_RELAX_SAMPLE | sed -e 's/:.*//g'`
  tmpfile=$(mktemp)
  sed -e "${ENCUT_LINE}d" $INCAR_RELAX_SAMPLE > $tmpfile
  sed -i -e "${ENCUT_LINE}i ENCUT = ${ENCUT}" $tmpfile
  cat $tmpfile > INCAR
  rm $tmpfile
  if [[ "$2" = "PBEsol" ]]; then
    echo "GGA = PS" >> INCAR
  fi
}

function revise_encut()
{
  ##### if $1 is less than 10, read ENMAX from POTCAR and excute ENMAX * $1
  ##### $1: ENCUT "1.3" or "500"
  if [ `echo $(($1<10))` -eq 1 ]; then
    source $MODULE_DIR/potcar.zsh
    ENMAX=`get_enmax_from_potcar "POTCAR"`
    ENCUT=`echo $(($ENMAX*$1)) | sed 's/\.[^\.]*$//'`
  else
    ENCUT=$1
  fi
  echo $ENCUT
}

function revise_incar_param()
{
  ##### $1: conf file
  ##### $2: param name
  ##### $3: var
  source $MODULE_DIR/conf.zsh
  revise_param $1 $2 $3
}
