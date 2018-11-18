#!/usr/bin/zsh

################################################################################
# phonon calculation against id-xxxxxx compound
################################################################################

### variables
THIS_FILE=`which $0`
PHONOSPIC_DIR=$(dirname  $(dirname $THIS_FILE))


### fuctions
function usage()
{
  cat <<EOF
  this script is a tool for phonon calculation against id-xxxxxx compound

  Options:
    -h          print usage

    --relax     make relax directory and files
        \$1: LDA or PBE or PBEsol
        \$2: number of KPOINTS "6 6 6"
        \$3: ENCUT ex) 1.3 or 500

    --relax_EV
        \$1: relax name  ex) "LDA_k666_1-3"

    --symmetrize
        \$1: POSCAR file

    --fc2       make fc2 directory and make displacements
        \$1: relax name  ex) "LDA_k666_1-3"
        \$2: DIM (for fc2)  ex) "4 4 4"

    --fc3       make fc3 directory and make displacements
        \$1: relax name  ex) "LDA_k666_1-3"
        \$2: DIM (for fc2)  ex) "4 4 4"

    --fc3_phdb  make fc3 displacements
        \$1: DIM (for fc3)  ex) "2 2 2"
               if $1="" => same as fc2 dim in phonondb
        \$2: KPOINTS (for fc3)  ex) "1 1 2"
               if $2="" => same as fc2 KPOINTS-force in phonondb

EOF
}

function dir_check()
{
  if [ $(basename `pwd` | cut -c 1-3) != "id-" ]; then
    echo "this script must be in the id-xxxxxx direcrtory"
    exit 1
  fi
}


function setup_relax()
{
  ##### $1: LDA or PBE or PBEsol
  ##### $2: number of KPOINTS "6 6 6"
  ##### $3: multiple ex) 1.3 or 500
  ##### $4: mode ex) None or test

  K_NUM=`echo $2 | sed -e 's/[^0-9]//g'`
  MULTI_NAME=`echo ${3/./-}`
  RELAX_DIR=relax/${1}_k${K_NUM}_${MULTI_NAME}
  COMP_ID=$(basename `pwd`)
  echo $RELAX_DIR

  ### check
  if [ -e $RELAX_DIR ]; then
    echo "$RELAX_DIR is already exists"
    exit 1
  fi

  mkdir -p $RELAX_DIR
  cp raw_data/POSCAR $RELAX_DIR
  phonospic-makefile.zsh --potcar raw_data/POSCAR $1 > $RELAX_DIR/POTCAR
  if [ -e "err_phonospic-makefile" ]; then
    echo "there is no POTCAR"
    rm -r err_phonospic-makefile
    exit 1
  fi
  phonospic-makefile.zsh --job_relax $COMP_ID > $RELAX_DIR/job_relax.sh
  phonospic-makefile.zsh --kpoints $2 > $RELAX_DIR/KPOINTS
  phonospic-makefile.zsh --incar_relax $RELAX_DIR/POTCAR $3 $1 > $RELAX_DIR/INCAR
}


function EV_curve()
{
  ##### $1: relax name  ex) "LDA_k666_1-3"
  COMP_ID=$(basename `pwd`)
  RLX_DIR="./relax/$1"
  TEST_DIR="${RLX_DIR}/EV_test"
  mkdir $TEST_DIR
  cp "${RLX_DIR}/INCAR" "$TEST_DIR"
  cp "${RLX_DIR}/POSCAR" "$TEST_DIR"
  cp "${RLX_DIR}/POTCAR" "$TEST_DIR"
  cp "${RLX_DIR}/KPOINTS" "$TEST_DIR"
  cp "${PHONOSPIC_DIR}/template/job_EV_curve.sh" "$TEST_DIR"
  cd $TEST_DIR
  sed -e s/"jobname"/"$COMP_ID"/g job_EV_curve.sh | qsub
  cd -
}


function ex_symmetrize()
{
  ##### $1: POSCAR file
  phonopy --symmetry --tolerance=1e-3 $1
  # sed -i -e "6i `head -1 BPOSCAR`" BPOSCAR

  BPOS_TOTAL=0
  BPOS_NUM=(`sed -n 7p BPOSCAR`)
  for i in `seq 1 ${#BPOS_NUM}`
  do
    BPOS_TOTAL=$(($BPOS_TOTAL+$BPOS_NUM[i]))
  done

  CONT_TOTAL=0
  CONT_NUM=(`sed -n 7p CONTCAR`)
  for i in `seq 1 ${#CONT_NUM}`
  do
    CONT_TOTAL=$(($CONT_TOTAL+$CONT_NUM[i]))
  done

  if [[ $BPOS_TOTAL != $CONT_TOTAL ]]; then
    echo "total num has changed"
    exit 1
  fi
}


function setup_fc()
{
  ##### $1: relax name  ex)"LDA_k666_1-3"
  ##### $2: DIM  ex) "4 4 4"
  ##### $3: "fc2" or "fc3"

  RELAX_DIR="relax/$1"
  DIM_FC=(`echo $2`)
  FC_DIR="${3}/${3}_$DIM_FC[1]$DIM_FC[2]$DIM_FC[3]_${1}"

  ### check
  if [ -e $FC_DIR ]; then
    echo "$FC_DIR is already exists"
    exit 1
  fi

  ### symmetrize
  cd $RELAX_DIR
  ex_symmetrize CONTCAR
  cd -

  ### make
  mkdir -p $FC_DIR
  COMP_ID=$(basename `pwd`)

  ### POTCAR
  cp $RELAX_DIR/POTCAR $FC_DIR/POTCAR

  ### POSCAR
  cp $RELAX_DIR/BPOSCAR $FC_DIR/POSCAR-unitcell


  ### INCAR
  phonospic-makefile.zsh --incar_${3} $RELAX_DIR/INCAR > $FC_DIR/INCAR

  ### KPOINTS
  KPOINTS_FC=()
  KNUM_RELAX=(`sed -n 4p ${RELAX_DIR}/KPOINTS`)
  for i in `seq 1 3`
  do
    NUM=$(($KNUM_RELAX[i] / $DIM_FC[i]))
    if [[ $(($KNUM_RELAX[i] % $DIM_FC[i])) != 0 ]];then
      NUM=$(($NUM+1))
    fi
    KPOINTS_FC=($KPOINTS_FC $NUM)
  done

  cp $RELAX_DIR/KPOINTS $FC_DIR/KPOINTS_relax
  sed -e "4d" $FC_DIR/KPOINTS_relax > $FC_DIR/KPOINTS
  sed -i -e "4i $KPOINTS_FC" $FC_DIR/KPOINTS
  rm $FC_DIR/KPOINTS_relax

  ### disp_fc.conf
  phonaly-makeconf.zsh --disp_conf "$2" > $FC_DIR/disp_${3}.conf

  ### make displacements and disp directory
  cd $FC_DIR
  if [ "$3" = "fc2" ];then
    phonopy disp_${3}.conf
  else
    phono3py disp_${3}.conf
  fi
  POS_NUM=(`find POSCAR-[0-9]*`)
  for i in $POS_NUM
  do
    NUM=${i:7}
    mkdir disp-$NUM
    CUR_DIR=`pwd`
    ln -s $CUR_DIR/POTCAR $CUR_DIR/disp-$NUM/POTCAR
    ln -s $CUR_DIR/KPOINTS $CUR_DIR/disp-$NUM/KPOINTS
    ln -s $CUR_DIR/INCAR $CUR_DIR/disp-$NUM/INCAR
    phonospic-makefile.zsh --job_${3} $COMP_ID $NUM > disp-$NUM/job_${3}.sh
    mv $i disp-$NUM/POSCAR
  done
}


function setup_fc_phdb()
{
  ##### $1: dim    ex) "" or "2 2 2"
  ##### $2: KPOINTS   ex) "" or "1 1 2"
  MP_DIR=`pwd`
  MP_NUM=$(basename `pwd`)

  ### DIM_NUM and make directory
  if [ "$1" = "" ]; then
    DIM_NUM=`grep DIM "$MP_DIR/togo/phonopy.conf" |
             sed s/"DIM = "/""/g | sed s/"0"/""/g`
    DN=`echo $DIM_NUM | sed s/" "/""/g`
    DIRNAME="$MP_DIR/fc3/fc3_${DN}_togo"
  else
    DIM_NUM="$1"
    DN=`echo $DIM_NUM | sed s/" "/""/g`
    DIRNAME="$MP_DIR/fc3/fc3_$DN"
  fi

  ### check
  if [ -e $DIRNAME ]; then
    echo "$DIRNAME is already exists"
    exit 1
  fi

  mkdir -p $DIRNAME

  phonaly-makeconf.zsh --disp_conf "$DIM_NUM"\
    > "$DIRNAME/disp_fc3.conf"

  ### fc3
  cp "$MP_DIR/togo/POSCAR-unitcell" "$DIRNAME"
  # cp "$MP_DIR/togo/INCAR" "$DIRNAME"
  cp "$MP_DIR/togo/INCAR-force" "$DIRNAME/INCAR"
  # cp "$MP_DIR/togo/KPOINTS" "$DIRNAME"

  if [ "$2" = "" ]; then
    cp "$MP_DIR/togo/KPOINTS-force" "$DIRNAME/KPOINTS"
  else
    KNUM=(`echo $2`)
    K_INPUT="\     $KNUM[1]     $KNUM[2]     $KNUM[3]"
    sed "4d" $MP_DIR/togo/KPOINTS-force | sed "4i $K_INPUT" > $DIRNAME/KPOINTS
  fi

  phonospic-makefile.zsh --potcar "$MP_DIR/togo/POSCAR-unitcell"\
    "PBEsol" > "$DIRNAME/POTCAR"


  ### make displacements and disp directory
  cd $DIRNAME
  phono3py disp_fc3.conf
  POS_NUM=(`find POSCAR-[0-9]*`)
  for i in $POS_NUM
  do
    NUM=${i:7}
    mkdir disp-$NUM
    CUR_DIR=`pwd`
    ln -s $CUR_DIR/POTCAR $CUR_DIR/disp-$NUM/POTCAR
    # ln -s $CUR_DIR/KPOINTS $CUR_DIR/disp-$NUM/KPOINTS
    # ln -s $CUR_DIR/INCAR $CUR_DIR/disp-$NUM/INCAR
    ln -s $CUR_DIR/KPOINTS $CUR_DIR/disp-$NUM/KPOINTS
    ln -s $CUR_DIR/INCAR $CUR_DIR/disp-$NUM/INCAR
    phonospic-makefile.zsh --job_fc3 $MP_NUM $NUM > disp-$NUM/job_fc3.sh
    mv $i disp-$NUM/POSCAR
  done
  echo "INCAR is the same as ones used in calculating fc2"
  echo "please check"
}


### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -relax -symmetrize -relax_EV -fc2 -fc3 -fc3_phdb

if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--relax]}" ]]; then
  dir_check
  setup_relax $1 $2 $3
  exit 0
fi

if [[ -n "${opthash[(i)--symmetrize]}" ]]; then
  ex_symmetrize $1
  exit 0
fi

if [[ -n "${opthash[(i)--relax_EV]}" ]]; then
  dir_check
  EV_curve $1
  exit 0
fi

if [[ -n "${opthash[(i)--fc2]}" ]]; then
  # dir_check
  setup_fc $1 $2 "fc2"
  exit 0
fi

if [[ -n "${opthash[(i)--fc3]}" ]]; then
  # dir_check
  setup_fc $1 $2 "fc3"
  exit 0
fi

if [[ -n "${opthash[(i)--fc3_phdb]}" ]]; then
  setup_fc_phdb $1 $2
  exit 0
fi

echo "nothing was executed. check the usage  =>  $(basename ${0}) -h"
exit 1
