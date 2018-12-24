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
  fi }

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
  PARAM_LINE=`cat "$1" | grep "$2 = "`
  if [ "$PARAM_LINE" = "" ]; then
    echo "$2 does not exist in $1"
    echo "return(251)"
    return 251
  fi
  tmpfile=$(mktemp)
  echo "revising : $PARAM_LINE => $2 = $3"
  cat "$1" | sed s/"$PARAM_LINE"/"$2 = $3"/g >> $tmpfile
  rm -f $1
  mv $tmpfile $1
  echo ""
  echo "~~ revised $1 ~~"
  cat $1
}

function make_new_incar_line_when_not_found()
{
  ##### $1: conf file
  ##### $2: param name
  ##### $3: var
  revise_incar_param $1 $2 $3
  if [ "$?" = 251 ]; then
    echo "there is no $2 param in $1 file, so make new line"
    echo "additional line is below"
    echo "$2 = $3" | tee -a $1
    echo ""
    echo "~~ revised $1 ~~"
    cat $1
  fi
}
