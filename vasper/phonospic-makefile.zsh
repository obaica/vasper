#!/usr/bin/zsh

###############################################################################
# make various files used in VASP calculation
###############################################################################

### variables
THIS_FILE=`which $0`
PHONOSPIC_DIR=$(dirname  $(dirname $THIS_FILE))
POT_DIR="$PHONOSPIC_DIR/database/potcar_auto"
TEMPLATE_DIR="$PHONOSPIC_DIR/template"

### sample data
INCAR_RELAX_SAMPLE="$TEMPLATE_DIR/INCAR_relax-sample"
JOB_RELAX_SAMPLE="$TEMPLATE_DIR/job_relax.sh-sample"


### fuctions
function usage()
{
  cat <<EOF

  Options: this script is a tool for makeing various files using VASP calculation

    -h evoke function usage

    --job_relax     make job_relax.sh
        \$1: compound name

    --job_fc2       make job_fc2.sh
        \$1: compound name
        \$2: disp number  ex) 002

    --job_fc3       make job_fc3.sh
        \$1: compound name
        \$2: disp number  ex) 00002

    --potcar        make POTCAR
        \$1: POSCAR file
        \$2: LDA or PBE or PBEsol

    --kpoints       make KPOINTS
        \$1: the number of mesh  ex) "6 6 6"

    --incar_relax   make INCAR for relax
        \$1: POTCAR file
        \$2: ENCUT ex) 1.3 or 500
        \$3: GGA ex) "" or "PBEsol"

    --incar_relax_test   make INCAR for relax test
        \$1: POTCAR file
        \$2: ENCUT ex) 1.3 or 500
        \$3: GGA ex) "" or "PBEsol"

    --incar_fc2   make INCAR for fc2
        \$1: INCAR file used for relaxing

    --incar_fc3   make INCAR for fc2
        \$1: INCAR file used for relaxing

EOF
}

function mk_job_relax()
{
  ##### $1: job name

  cat $TEMPLATE_DIR/job_relax.sh |
  sed s/"jobname"/"${1}_relax"/g
}


function mk_job_fc2()
{
  ##### $1: job name
  ##### $2: disp number

  echo "#$ -S /usr/bin/zsh"
  echo "#$ -cwd"
  echo "#$ -N ${1}_fc2-${2}"
  echo "#$ -pe mpi* 32"
  echo "#$ -e err.log"
  echo "#$ -o std.log"
  echo ""
  echo "source /home/mizo/.zshrc"
  echo "ulimit -u unlimited"
  echo ""
  echo "mpirun vasp541mpi"
}


function mk_job_fc3()
{
  ##### $1: job name
  ##### $2: disp number

  echo "#$ -S /usr/bin/zsh"
  echo "#$ -cwd"
  echo "#$ -N ${1}_fc3-${2}"
  echo "#$ -pe mpi* 16"
  echo "#$ -e err.log"
  echo "#$ -o std.log"
  echo ""
  echo "source /home/mizo/.zshrc"
  echo "ulimit -u unlimited"
  echo ""
  echo "mpirun vasp541mpi"
}


function mk_POTCAR()
{
  ##### $1: POSCAR file
  ##### $2: LDA or PBE or PBEsol

  ### check $2
  if [ $2 != LDA -a $2 != PBE ] && [ $2 != PBEsol ]; then
    echo "LDA or PBE or PBEsol doesn't set" > err_phonospic-makefile
    exit 1
  fi

  ### make
  POTCAR_=()
  ELEMENTS=(`sed -n 6p $1`)

  if [[ $ELEMENTS = "" ]]; then
    echo "couldn't extract elements from POSCAR file" > err_phonospic-makefile
    exit 1
  fi

  for i in $ELEMENTS
  do
    POT_XC=`echo $2 | sed s/"sol"//g`
    POT_COUNT=`ls ${POT_DIR} | grep "^${i}_" | grep "$POT_XC" | wc -l`
    if [[ $POT_COUNT = 0 ]]; then
      echo "there is no POTCAR" > err_phonospic-makefile
      exit 1
    fi
    POT=`ls ${POT_DIR} | grep "^${i}_" | grep "$POT_XC"`
    POTCAR_=($POTCAR_ $POT)
  done

  for i in $POTCAR_
  do
    cat $POT_DIR/$i
  done

  exit 0
}


function mk_KPOINTS()
{
  ##### $1: number of mesh  ex) "6 6 6"

  ### check
  ARGNUM=(`echo $1`)
  if [ $#ARGNUM != 3 ]; then
    echo "KPOINTS is not set correctly"
    exit 1
  fi

  ### make
  echo "Automatic mesh"
  echo "0"
  echo "Monkhorst-pack"
  echo $1
  echo " 0.000 0.000 0.000"
  #echo " 0.500 0.500 0.000" >> $kfile

  exit 0
}


function mk_INCAR_relax()
{
  ##### $1: POTCAR file
  ##### $2: multiple  ex) 1.3 or 500
  ##### $3: GGA  ex) "" or "PBEsol"
  ##### $4: mode  ex) "" or "test"

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

  ### ENCUT
  ARG_FOR_TEST=`echo "$2" | grep "\."`
  if [ -n "$ARG_FOR_TEST" ]; then
    ENCUT=`echo $(($MAX*$2)) | sed 's/\.[^\.]*$//'`
  else
    ENCUT=$2
  fi

  ENCUT_LINE=`grep -n ENCUT $INCAR_RELAX_SAMPLE | sed -e 's/:.*//g'`
  tmpfile=$(mktemp)
  sed -e "${ENCUT_LINE}d" $INCAR_RELAX_SAMPLE > $tmpfile
  sed -i -e "${ENCUT_LINE}i \     ENCUT = ${ENCUT}" $tmpfile

  cat $tmpfile
  rm $tmpfile

  if [[ "$3" = "PBEsol" ]]; then
    echo "       GGA = PS"
  fi
}


function mk_INCAR_fc2()
{
  ##### $1: INCAR file used for relaxing
  sed s/"`grep IBRION $1`"/"    IBRION = -1"/g $1 |
  sed -e s/"`grep NSW $1`"/"       NSW = 0"/g
  echo "      KPAR = 2" }


function mk_INCAR_fc3()
{
  ##### $1: INCAR file used for relaxing
  sed s/"`grep IBRION $1`"/"    IBRION = -1"/g $1 |
  sed -e s/"`grep NSW $1`"/"       NSW = 0"/g
}


function mk_fchdf_conf()
{
  grep DIM disp_fc3.conf
  grep DIM disp_fc2.conf | sed s/"DIM"/"DIM_FC2"/g
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "CELL_FILENAME = POSCAR-unitcell"
  echo "SYMMETRIZE_FC2 = .TRUE."
  echo "SYMMETRIZE_FC3 = .TRUE."
  echo "TRANSLATION = .TRUE."
}


function mk_kappa_conf()
{
  ##### $1: the number of mesh
  grep DIM disp_fc3.conf
  grep DIM disp_fc2.conf | sed s/"DIM"/"DIM_FC2"/g
  echo "MESH = $1"
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "BTERTA = .TRUE."
  echo "NAC = .TRUE."
  echo "READ_FC2 = .TRUE."
  echo "READ_FC3 = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
}


### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -job_relax -job_fc2 -job_fc3 -potcar -kpoints \
           -incar_relax -incar_relax_test -incar_fc2 -incar_fc3

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--job_relax]}" ]]; then
  mk_job_relax $1
  exit 0
fi

if [[ -n "${opthash[(i)--job_fc2]}" ]]; then
  mk_job_fc2 $1 $2
  exit 0
fi

if [[ -n "${opthash[(i)--job_fc3]}" ]]; then
  mk_job_fc3 $1 $2
  exit 0
fi

if [[ -n "${opthash[(i)--potcar]}" ]]; then
  mk_POTCAR $1 $2
  exit 0
fi

if [[ -n "${opthash[(i)--kpoints]}" ]]; then
  mk_KPOINTS $1
  exit 0
fi

if [[ -n "${opthash[(i)--incar_relax]}" ]]; then
  mk_INCAR_relax $1 $2 $3
  exit 0
fi

if [[ -n "${opthash[(i)--incar_relax_test]}" ]]; then
  mode='test'
  mk_INCAR_relax $1 $2 $3 $mode
  exit 0
fi

if [[ -n "${opthash[(i)--incar_fc2]}" ]]; then
  mk_INCAR_fc2 $1
  exit 0
fi

if [[ -n "${opthash[(i)--incar_fc3]}" ]]; then
  mk_INCAR_fc3 $1
  exit 0
fi

echo "nothing was executed. check the usage  =>  $(basename ${0}) -h"
exit 2
