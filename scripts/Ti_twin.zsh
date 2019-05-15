#!/usr/bin/zsh

###############################################################################
# make various directories
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file makes various directories.

  Options:

    -h evoke function usage

    --make_shear_dir           make shear directories
        \$1: 'stropt_GGA_375_gamma'

    --vasp_rerun       rerun relax or posiopt
        \$1: posiopt or stropt directory
        \$2: INCAR

    --shear_fc2       setup fc2 calculation
        \$1: ex. './shear/stropt_GGA_375_gamma/10-11/shear_10-11_0.500'

    --modulation      modulation
        \$1: ex. './shear/stropt_GGA_375_gamma/10-11/shear_10-11_0.500/fc2'

    --band       make band figure and store in ./figure/band/...
        \$1: ex. './shear/stropt_GGA_375_gamma/10-11'

    --band_dos       make band_dos figure and store in ./figure/band_dos/...
        \$1: ex. './shear/stropt_GGA_375_gamma/10-11'

    --relax_test     make relax test
        \$1: test directroy    ex. ./stropt/kptest
        \$2: vasper_relax.conf
        \$3: ENCUT    ex. "300 350 400 450"
        \$4: KPOINTS    ex. "10 10 8, 12 12 10, 14 14 10"

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : Unexpected argments were parsed.
    250 : You tried to run in the uncorrect directory.

EOF
}

### envs
source $HOME/.vasperrc

### modules
source $MODULE_DIR/error-codes.zsh

### variables
Ti_twin_DIR=`pwd`


### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -make_shear_dir -vasp_rerun -shear_fc2 -band -band_dos -modulation -relax_test

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--make_shear_dir]}" ]]; then
  ##### $1: 'stropt_GGA_375_gamma'
  argnum_check "1" "$#"
  file_exists_check "stropt/$1"
  file_exists_check "setting/vasp/$1"
  SHEAR_DIR="./shear/$1"
  file_does_not_exist_check "$SHEAR_DIR"

  TWINTYPE=('10-12' '10-11' '11-22' '11-21')
  OPT_NUM=`ls stropt/$1 | grep 'opt' | wc -l`
  echo "relax directory : stropt/$1/opt${OPT_NUM}"
  (cd "./stropt/$1/opt${OPT_NUM}"; phonopy --symmetry -c CONTCAR)
  for i in $TWINTYPE
  do
    mkdir -p $SHEAR_DIR/$i
    for j in {0..20}
    do
      x=`printf $(echo '%.3f \n' $((0.05*$j)))`
      # twinpy-poscar.py -c "./stropt/$1/opt${OPT_NUM}/CONTCAR" -t $i -x $x
      # twinpy-poscar.py -c "./stropt/$1/opt${OPT_NUM}/CONTCAR" -t $i -x $x
      twinpy-poscar.py -c "./stropt/$1/opt${OPT_NUM}/BPOSCAR" -t $i -x $x
      STORE_DIRNAME="$SHEAR_DIR/$i/shear_${i}_${x}"
      mkdir -p $STORE_DIRNAME/posiopt/opt1
      mv `ls | grep TPOSCAR` $STORE_DIRNAME/posiopt/opt1/POSCAR
      cp setting/vasp/$1/KPOINTS $STORE_DIRNAME/posiopt/opt1
      cp setting/vasp/$1/job_relax.sh $STORE_DIRNAME/posiopt/opt1
      cp setting/vasp/$1/POTCAR $STORE_DIRNAME/posiopt/opt1
      cp setting/vasp/$1/INCAR_posiopt_rough $STORE_DIRNAME/posiopt/opt1/INCAR
      mv `ls | grep yaml` $STORE_DIRNAME
    done
  done
  exit 0
fi

if [[ -n "${opthash[(i)--vasp_rerun]}" ]]; then
  ##### $1: posiopt directory
  ##### $2: INCAR
  argnum_check "2" "$#"
  # if [ ! "`basename $1`" = "posiopt" ] && [ ! "`basename $1`" = "stropt" ] && [ ! "`basename $1`" = "relaxtest" ];then
  #   echo `dirname $1`
  #   echo "unexpected input $1"
  #   exit 1
  # fi
  FINAL_OPT_NUM=`find $1 -type d -name opt\* | wc -l`
  mkdir $1/opt$(($FINAL_OPT_NUM+1))
  cp "$2" "$1/opt$(($FINAL_OPT_NUM+1))/INCAR"
  (cd $1/opt$FINAL_OPT_NUM; cp KPOINTS POTCAR job_relax.sh ../opt$(($FINAL_OPT_NUM+1)); cp CONTCAR ../opt$(($FINAL_OPT_NUM+1))/POSCAR)
  exit 0
fi

if [[ -n "${opthash[(i)--shear_fc2]}" ]]; then
  ##### $1: ex. './shear/stropt_GGA_375_gamma/10-11/shear_10-11_0.500'
  argnum_check "1" "$#"
  file_exists_check "$1"
  tmpfile=$(mktemp)
  cat ./setting/vasper/vasper_fc2.conf >> $tmpfile
  echo "# my setting" >> $tmpfile
  echo "P_DIRNAME=fc2" >> $tmpfile
  OPTDIR=`ls $1/posiopt | sort | tail -n 1`
  echo "P_RELAX_DIRNAME=posiopt/$OPTDIR" >> $tmpfile
  echo "P_JOBNAME=`basename $1`_fc2" >> $tmpfile
  echo "P_POSCAR=posiopt/$OPTDIR/CONTCAR" >> $tmpfile
  # echo "P_POSCAR=posiopt/$OPTDIR/BPOSCAR" >> $tmpfile
  # (cd $1/posiopt/$OPTDIR; phonopy --symmetry -c CONTCAR)
  (cd $1; vasper-makedir.zsh --fc2 $tmpfile; cd fc2; vasper-makedir.zsh --disp disp_fc2.conf)
  exit 0
fi

if [[ -n "${opthash[(i)--band]}" ]]; then
  ##### $1: ex. './shear/stropt_GGA_375_gamma/10-11'
  argnum_check "1" "$#"
  file_exists_check "$1"
  for i in `find $1 -type d -name fc2`
  do
    cp ./setting/phonopy/band.conf $i
    cd $i
    phonopy band.conf -p -s
    STROPT=`basename $(dirname $1)`
    SHEAR=`basename $1`
    mkdir -p $Ti_twin_DIR/figure/band/$STROPT/$SHEAR
    cp band.pdf $Ti_twin_DIR/figure/band/$STROPT/$SHEAR/band_`basename $(dirname $i)`.pdf
    cd $Ti_twin_DIR
  done
  exit 0
fi

if [[ -n "${opthash[(i)--band_dos]}" ]]; then
  ##### $1: ex. './shear/stropt_GGA_375_gamma/10-11'
  argnum_check "1" "$#"
  file_exists_check "$1"
  for i in `find $1 -type d -name fc2`
  do
    cp ./setting/phonopy/band_dos.conf $i
    cd $i
    phonopy band_dos.conf -p -s
    STROPT=`basename $(dirname $1)`
    SHEAR=`basename $1`
    mkdir -p $Ti_twin_DIR/figure/band_dos/$STROPT/$SHEAR
    cp band_dos.pdf $Ti_twin_DIR/figure/band_dos/$STROPT/$SHEAR/band_dos_`basename $(dirname $i)`.pdf
    cd $Ti_twin_DIR
  done
  exit 0
fi

if [[ -n "${opthash[(i)--modulation]}" ]]; then
  ##### $1: ex. './shear/stropt_GGA_375_gamma/10-11/fc2'
  argnum_check "1" "$#"
  cp ./modulation.conf $1
  cd $1
  phonopy modulation.conf
  mkdir -p modulation/opt1
  cp MPOSCAR-001 modulation/opt1/POSCAR
  cp ~/project/Ti_twin/KPOINTS modulation/opt1
  cp ../posiopt/opt1/POTCAR modulation/opt1
  cp ../posiopt/opt1/INCAR modulation/opt1
  cp ../posiopt/opt1/job_relax.sh modulation/opt1
  exit 0
fi

if [[ -n "${opthash[(i)--relax_test]}" ]]; then
   ##### $1: test directroy    ex. ./stropt/kptest
   ##### $2: vasper_relax.conf
   ##### $3: ENCUT    ex. "300 350 400 450"
   ##### $4: KPOINTS    ex. "10 10 8, 12 12 10, 14 14 10"
  argnum_check "4" "$#"
  if [ ! -e "$1" ]; then
    mkdir "$1"
  fi
  for EN in `echo $3`
  do
    comma_num=`echo $4 | sed s/"[0-9 ]"//g`
    arr_num=$(($#comma_num+1))
    for i in {1..${arr_num}}
    do
      KP=`echo $4 | cut -f $i -d ","`
      vasper-makefile.zsh --revise_setting "$2" "P_ENCUT" "$EN"
      vasper-makefile.zsh --revise_setting "$2" "P_KNUM" "$KP"
      vasper-makefile.zsh --revise_setting "$2" "P_DIRNAME" "$1/stropt_${EN}_`echo $KP | sed s/" "/""/g`_gamma/opt1"
      vasper-makefile.zsh --revise_setting "$2" "P_JOBNAME" "stropt_${EN}_`echo $KP | sed s/" "/""/g`_gamma_relax"
      vasper-makedir.zsh --relax "$2"
    done
  done
  exit 0
fi

nothing_excuted
