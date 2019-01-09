#!/usr/bin/zsh

###############################################################################
# functions for making various qsystem style
###############################################################################

function disp_qsub()
{
  ##### $1 : job file name
  if [ -e "vasper_job.log" ]; then
    rm -f "vasper_job.log"
  fi
  echo "job-id dirname" > "vasper_job.log"
  for i in disp-*
  do
    cd $i
    DIRNAME=`basename $(pwd)`
    COMMENT=`qsub $1`
    JOB_ID=`echo $COMMENT | cut -d " " -f 3`
    echo "$COMMENT"
    echo "$JOB_ID $DIRNAME" >> "../vasper_job.log"
    cd -
  done
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

function revised_qstat()
{
  qstat | tail -n +3 | sed -E 's/[\t ]+/ /g' | sed s/"^ "/""/g
}