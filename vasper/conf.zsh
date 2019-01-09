#!/usr/bin/zsh

###############################################################################
# functions for making various conf file
###############################################################################

# function cat_conf()
# {
#   ##### $1 : option, "relax" or ...
#   if [ "$1" = "relax" ]; then
#     cat "$TEMPLATE_DIR/relax.conf"
#   else
#     echo "unexpected parser : $1"
#     echo "exit(251)"
#     exit 251
#   fi
# }

function disp_conf()
{
  ##### $1: filetype
  ##### $2: dim ex. "3 3 3"
  ##### $3: 'alm' => temperature
  ##### $4: 'alm' => the number of displacement
  if [ "$1" = "alm" ]; then
    {
      echo "DIM = $2"
      echo "TEMPERATURE = $3"
      echo "DISP_NUM = $4"
    } > disp_${1}.conf
  elif [ "$1" = "fc2" -o "$1" = "fc3" ]; then
    {
      echo "CREATE_DISPLACEMENTS = .TRUE."
      echo "CELL_FILENAME = POSCAR-unitcell"
      echo "DIM = $2"
    }  > disp_${1}.conf
  else
    unexpected_args "$1"
  fi
}

function dos_pdos_conf()
{
  ##### $1: 'dos'
  ##### $2: disp.conf
  ##### $3: mesh
  FILENAME=${1}-m`echo "$3" | sed s/" "/""/g`.conf
  file_does_not_exist_check "$FILENAME"
  touch $FILENAME
  {
    grep "DIM" "$2"
    echo "MESH = $3"
    echo "GAMMA_CENTER = .TRUE."
    echo "GROUP_VELOCITY = .TRUE."
    echo "NAC = .TRUE."
    echo "TETRAHEDRON = .TRUE."
    echo "CELL_FILENAME = POSCAR-unitcell"
  } >> $FILENAME
  if [ "$1" = "dos" ]; then
    {
      echo "DOS = .TRUE."
      echo "MESH_FORMAT = HDF5"
    } >> $FILENAME
  # elif [ $1 = "pdos" ]; then
  #   poscry-phonoconf.py --posfile="POSCAR-unitcell" --pdos
  #   echo "WRITE_MESH = .FALSE."
  else
    unexpected_args "$1"
  fi
}

function remove_conf_setting()
{
  ##### $1: conf file
  ##### $2: param name
  if [ `cat $1 | grep "$2="` = "" ]; then
    echo "param : $2 does not exist in $1"
    echo "exit(251)"
    exit 251
  else
    echo "remove `grep $2= $1`"
    tmpfile=$(mktemp)
    grep -v "$2=" "$1" >> $tmpfile
    rm -f $1
    mv $tmpfile $1
    echo ""
    echo "~~ removed $1 ~~"
    cat $1
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
