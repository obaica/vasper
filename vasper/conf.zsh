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

function revise_param()
{
  ##### $1: conf file
  ##### $2: param name
  ##### $3: var
  PARAM_LINE=`cat "$1" | grep "$2 = "`
  if [ "$PARAM_LINE" = "" ]; then
    echo "$2 does not exist in $1"
    echo "exit(251)"
    exit 251
  fi
  PARAM_LINE_NUM=`cat "$1" | grep -n "$2 = " | sed -e 's/:.*//g'`
  OLD_PARAM=`echo $PARAM_LINE | sed s/"$2 = "/""/g | sed s/" "/""/g`
  NEW_PARAM_LINE=`echo $PARAM_LINE | sed s/"$OLD_PARAM"/"$3"/g`
  tmpfile=$(mktemp)
  sed -e "${PARAM_LINE_NUM}d" $1 >> $tmpfile
  sed -i -e "${PARAM_LINE_NUM}i `echo $NEW_PARAM_LINE`" $tmpfile
  rm -f $1
  mv $tmpfile $1
}
