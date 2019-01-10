#!/usr/bin/zsh

###############################################################################
# functions for making various qsystem style
###############################################################################

function revised_qstat()
{
  qstat | tail -n +3 | sed -E 's/[\t ]+/ /g' | sed s/"^ "/""/g
}

function execute_qsub()
{
  ##### $1 : job file
  ##### $2 : que name
  ##### if $2 is not specified qsub normally
  ##### else qsub -q $1
  if [ "$2" = "" ]; then
    qsub "$1"
  else
    qsub -q "$2" "$1"
  fi
}

function check_status()
{
  ##### $1 : job id
  revised_qstat | grep "$1 " | cut -d " " -f 5
}


function disp_qsub()
{
  ##### $1 : job file name
  ##### $2 : que name
  if [ -e "vasper_job.log" ]; then
    rm -f "vasper_job.log"
  fi
  echo "job-id dirname status" > "vasper_job.log"
  for i in disp-*
  do
    cd $i
    DIRNAME=`basename $(pwd)`
    COMMENT=`execute_qsub "$1" "$2"`
    JOB_ID=`echo $COMMENT | cut -d " " -f 3`
    echo "$COMMENT"
    echo "$JOB_ID $DIRNAME wait" >> "../vasper_job.log"
    cd -
  done
}

function revise_vasper_job_status()
{
  ##### $1 : vasper_job.log
  ##### $2 : job id
  ##### $3 : status
  OLD_LINE=`cat "$1" | grep "$2"`
  NEW_LINE=$(echo `cat "$1" | grep "$2" |  cut -d " " -f 1-2` "$3")
  tmpfile=$(mktemp)
  cat "$1" | sed s/"$OLD_LINE"/"$NEW_LINE"/g >> "$tmpfile"
  rm -f "$1"
  mv "$tmpfile" "$1"
}


# function add_at_specific_line()
# {
#   ##### $1: filename
#   ##### $2: grep $2
#   ##### $3: add words
#   LINE=`cat "$1" | grep "$2"`
#   if [ ! "`echo "$LINE" | wc -l`" = "1" ]; then
#     echo "$2 can find multiple lines"
#     echo "return(251)"
#     return 251
#   fi
#   tmpfile=$(mktemp)
#   cat "$1" | sed s/"$LINE"/"$LINE $3"/g >> $tmpfile
#   rm -f $1
#   mv $tmpfile $1
# }
