#!/usr/bin/zsh

###############################################################################
# functions for relaxation
###############################################################################

function getoptnum()
{
  # get the opt directory number to make
  local NUM=`find . -mindepth 1 -maxdepth 1 -type d -name opt\* | wc -l`
  # if [ $NUM = 0 ]; then
  #   NUM=$(($NUM+1))
  # fi
  echo $NUM
}

function checkfiles()
{
  # check whether necessary files exist in the current directory
  local FILES=(INCAR KPOINTS POTCAR POSCAR vasper_relax.dat)
  for FILE in $FILES
  do
    file_exists_check $FILE
  done
}

function makeoptdir()
{
  # make opt[num] directory
  # if opt* directories exist, remove the last one and remake
  ##### $1 : repeat number
  local DIRNAME="opt${1}"
  if [ -e "$DIRNAME" ]; then
    rm -rf $DIRNAME
  fi
  mkdir $DIRNAME
  cp INCAR $DIRNAME
  cp KPOINTS $DIRNAME
  ln -s `pwd`/POTCAR $DIRNAME
  if [ "$1" = 1 ]; then
    cp POSCAR $DIRNAME
  else
    cp "opt$((${1}-1))"/CONTCAR $DIRNAME/POSCAR
  fi
}

function repeat_setting()
{
  ##### $1 : repeat number
  # local COLUMNS=(`head -n 1 vasper_relax.dat | tr -s " "`)
  COLUMN=(`head -n 1 vasper_relax.dat | tr -s " "`)
  local COLUMN_NUM=$#COLUMN
  for i in {2..$COLUMN_NUM}
  do
    local VAR=`cat vasper_relax.dat | tr -s " " | cut -f ${i} -d " " | sed -n $((${1}+1))p`
    if [ "$COLUMN[$i]" = "REPEAT" ]; then
      MAX_REPEAT="$VAR"
    else
      vasper-makefile.zsh --revise_setting "INCAR" "$COLUMN[$i]" "$VAR"
    fi
  done
}

function run()
{
  # this function must be in the opt[num] directory
  ##### $1 : repeat max number

  function copyfiles()
  {
    ##### $1 : repeat number
    local FILES=(CONTCAR OUTCAR vasprun.xml OSZICAR vasper-log.yaml)
    for FILE in $FILES
    do
      if [ -e $FILE ]; then
        cp $FILE ${FILE}_${1}
      fi
    done
  }

  cp POSCAR POSCAR_0
  for i in {1..${1}}
  do
    /usr/local/calc/openmpi/bin/mpirun /usr/local/calc/vasp/vasp541mpi
    vasper-log.py -ym
    if [ ! -e "vasper-log.yaml" ]; then
      if [ -e "CONTCAR" ]; then
        copyfiles $i
        return 0
      else
        echo "there is not COUTCAR and vaspper-log.yaml file"
        echo "some error occured"
        exit 1
      fi

    else
      copyfiles $i
      local CONVERGE=`vasper-log.py --all | grep converged | rev | cut -f 1 -d " " | rev`
      if [ "$CONVERGE" = "True" ]; then
        return 0
      fi
    fi
    mv CONTCAR POSCAR
  done
  echo "too many repeats"
  exit 1
}
