#!/usr/bin/zsh

###############################################################################
# functions for making job.sh file
###############################################################################

function cat_conf()
{
  ##### $1 : option, "relax" or ...
  if [ "$1" = "relax" ]; then
    cat "$TEMPLATE_DIR/relax.conf"
  else
    echo "unexpected parser : $1"
    echo "exit(251)"
    exit 251
  fi
}

function revise_conf_param()
{
  ##### $1: conf file
  ##### $2: param name
  ##### $3: var
  PARAM_LINE=`cat "$1" | grep "${2}="`
  if [ "$PARAM_LINE" = "" ]; then
    echo "$2 does not exist in $1"
    echo "return(251)"
    return 251
  fi
  tmpfile=$(mktemp)
  echo "revising : $PARAM_LINE => $2=\"$3\""
  cat "$1" | sed s/"$PARAM_LINE"/"${2}=\"$3\""/g >> $tmpfile
  rm -f $1
  mv $tmpfile $1
  echo ""
  echo "~~ revised $1 ~~"
  cat $1
}

function make_new_conf_line_when_not_found()
{
  ##### $1: conf file
  ##### $2: param name
  ##### $3: var
  revise_conf_param $1 $2 $3
  if [ "$?" = 251 ]; then
    echo "there is no $2 param in $1 file, so make new line"
    echo "additional line is below"
    echo "$2=\"$3\"" | tee -a $1
    echo ""
    echo "~~ revised $1 ~~"
    cat $1
  fi
}
