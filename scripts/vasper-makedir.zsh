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

    --alm            make alm directory
        \$1: 'vasper_alm.conf'

    --band          make band directory
        \$1: relax dirname
        \$2: new directory name

    --born          make band directory
        \$1: relax dirname
        \$2: new directory name

    --disp          make disp directories
        \$1: 'disp_fc2.conf' 'disp_alm.conf'

    --dos           make dos directory
        \$1: relax dirname
        \$2: new directory name

    --fc2           make fc2 directory
        \$1: 'vasper_fc2.conf'

    --lobster       make lobster directory
        \$1: relax dirname
        \$2: new directory name
        \$3: calculate n th neighbor atoms ex. "2"

    --raw_data      make raw_data directory
        \$1: abs path to POSCAR
        \$2: tolerance parse to phonopy, 1e-5 is phonopy default

    --relax         make relax directory
        \$1: 'vasper_relax.conf'
        \$2: 'vasper_relax.dat'

    --relax_multi   make multiple relax directory
        \$1: 'vasper_relax.conf'
        \$2: 'vasper_relax.dat'
        \$3: ENCUT    ex. "300 350 400 450"
        \$4: KPOINTS    ex. "10 10 8, 12 12 10, 14 14 10"
        \$5: SIGMA    ex. "0.05 0.1 0.2 0.3"

    --static        make static directory
        \$1: relax dirname
        \$2: static dirname

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.  253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : Unexpected argments were parsed.
    250 : You tried to run in the uncorrect directory.

EOF
}

### envs
source $HOME/.vasperrc

### modules
source $MODULE_DIR/error-codes.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -alm -band -born -disp -dos -fc2 -lobster -raw_data -relax -relax_multi -static

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--alm]}" ]]; then
  ##### $1: alm conf
  source $1
  argnum_check "1" "$#"
  file_exists_check "$P_FC2_DIRNAME/FORCE_SETS"
  file_exists_check "$P_BORN_DIRNAME/BORN"
  file_does_not_exist_check "$P_DIRNAME"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $P_FC2_DIRNAME/job_fc2.sh | sed s/"fc2"/"alm"/g`
  FC2_DIR=$(cd $P_FC2_DIRNAME; pwd)
  BORN_DIR=$(cd $P_BORN_DIRNAME; pwd)
  echo "making $P_DIRNAME directory"
  echo "copying POSCAR-unitcell INCAR KPOINTS in $P_FC2_DIRNAME to $P_DIRNAME"
  mkdir -p $P_DIRNAME
  cp $1 $P_DIRNAME
  cp $P_FC2_DIRNAME/POSCAR-unitcell $P_DIRNAME
  cp $P_FC2_DIRNAME/POTCAR $P_FC2_DIRNAME/INCAR $P_FC2_DIRNAME/KPOINTS $P_DIRNAME
  echo "copying $P_BORN_DIRNAME/BORN and $P_FC2_DIRNAME/FORCE_SETS to $P_DIRNAME/calc0"
  cp $P_BORN_DIRNAME/BORN $P_DIRNAME
  mkdir $P_DIRNAME/calc0
  cp $P_FC2_DIRNAME/FORCE_SETS $P_DIRNAME/calc0
  DIM="`cat ${P_FC2_DIRNAME}/disp_fc2.conf | grep DIM | sed s/"DIM = "/""/g`"
  cd $P_DIRNAME
  touch "vasper.log"
  echo "fc2 directory : $FC2_DIR" >> "vasper.log"
  echo "born directory : $BORN_DIR" >> "vasper.log"
  echo "making job_alm.sh"
  vasper-makefile.zsh --job "alm" "$JOBNAME"
  echo "making disp_alm.conf"
  vasper-makefile.zsh --get_conf "disp_alm" "$DIM" "$P_TEMP" "$P_DISP_NUM"
  echo "made"
  exit 0
fi

if [[ -n "${opthash[(i)--band]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"band"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR in $1 to $2"
  mkdir -p $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "makeing job_band.sh"
  vasper-makefile.zsh --job "band" "$JOBNAME"
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints "band" "100" "POSCAR"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_band "INCAR"
  exit 0
fi

if [[ -n "${opthash[(i)--born]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"born"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $1 to $2"
  mkdir -p $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $1/KPOINTS $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "makeing job_born.sh"
  vasper-makefile.zsh --job "born" "$JOBNAME"
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_multi "KPOINTS" "2"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_born "INCAR"
  exit 0
fi

if [[ -n "${opthash[(i)--disp]}" ]]; then
  ##### $1: 'disp_fc2.conf' 'disp_alm.conf'
  source $MODULE_DIR/phonopy.zsh
  argnum_check "1" "$#"
  if [ "$1" = "disp_fc2.conf" ]; then
    file_does_not_exist_check "disp-001"
    make_disp_files "fc2" "$1"
    make_disp_dirs "fc2"
  elif [ "$1" = "disp_alm.conf" ]; then
    DISP_DIRNAME=`get_alm_dirname "next"`
    echo "DISP_DIRNAME : $DISP_DIRNAME"
    FS_PATH=`get_alm_dirname "last"`/FORCE_SETS
    file_exists_check $FS_PATH
    file_does_not_exist_check "disp-001"
    make_disp_files "alm" "$1" "$FS_PATH"
    make_disp_dirs "alm"
    mkdir $DISP_DIRNAME
    mv disp-0* $DISP_DIRNAME
    echo "FORCE_SETS file path : `pwd`/$FS_PATH" > "$DISP_DIRNAME/vasper.log"
  else
    echo "$1 is not supported"
    unexpected_args
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--dos]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"dos"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $1 to $2"
  mkdir -p $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $1/KPOINTS $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "makeing job_dos.sh"
  vasper-makefile.zsh --job "dos" "$JOBNAME"
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_multi "KPOINTS" "2"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_dos "INCAR"
  exit 0
fi

if [[ -n "${opthash[(i)--fc2]}" ]]; then
  ##### $1: vasper_fc2 conf
  source $1
  argnum_check "1" "$#"
  file_exists_check "$P_RELAX_DIRNAME"
  file_does_not_exist_check "$P_DIRNAME"
  source $MODULE_DIR/makejob.zsh
  if [ "$P_JOBNAME" = "" ]; then
    P_JOBNAME="fc2"
  fi
  if [ -e $P_RELAX_DIRNAME/job_relax.sh ]; then
    JOBNAME=`get_jobname_from_file $P_RELAX_DIRNAME/job_relax.sh | sed s/"relax"/"$P_JOBNAME"/g`
  else
    JOBNAME=`get_jobname_from_file $P_RELAX_DIRNAME/job_static.sh | sed s/"static"/"$P_JOBNAME"/g`
  fi
  RELAX_DIR=$(cd $P_RELAX_DIRNAME; pwd)
  echo "making $P_DIRNAME directory"
  echo "copying INCAR KPOINTS in $P_RELAX_DIRNAME to $P_DIRNAME"
  mkdir -p $P_DIRNAME
  cp $1 $P_DIRNAME/vasper_fc2.conf
  cp $P_RELAX_DIRNAME/POTCAR $P_RELAX_DIRNAME/INCAR $P_RELAX_DIRNAME/KPOINTS $P_DIRNAME
  echo "copying $P_POSCAR to $P_DIRNAME/POSCAR-unitcell"
  cp $P_POSCAR $P_DIRNAME/POSCAR-unitcell
  cd $P_DIRNAME
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "making job_fc2.sh"
  vasper-makefile.zsh --job "fc2" "$JOBNAME"
  echo ""
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_newmesh "KPOINTS" "$P_KNUM"
  echo ""
  echo "revising INCAR"
  vasper-makefile.zsh --incar_fc2 "INCAR"
  echo ""
  echo "disp_fc2.conf file"
  vasper-makefile.zsh --get_conf "disp_fc2" "$P_DIM"
  echo "made"
  exit 0
fi

if [[ -n "${opthash[(i)--lobster]}" ]]; then
  ##### $1: relax dirname
  ##### $2: new directory name
  ##### $3: calculate n th neighbor atoms ex. "2"
  argnum_check "3" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"lobster"/g`
  RELAX_DIR=$(cd $1; pwd)
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $1 to $2"
  mkdir -p $2
  cp $1/CONTCAR $2/POSCAR
  cp $1/POTCAR $1/INCAR $1/KPOINTS $2
  cd $2
  echo "relax directory : $RELAX_DIR" > "vasper.log"
  echo "making job_lobster.sh"
  vasper-makefile.zsh --job "lobster" "$JOBNAME"
  echo ""
  echo "revising KPOINTS"
  vasper-makefile.zsh --kpoints_multi "KPOINTS" "2"
  echo ""
  echo "revising INCAR"
  vasper-makefile.zsh --incar_lobster "INCAR" "$RELAX_DIR/vasprun.xml" "POSCAR" "POTCAR"
  echo ""
  echo "making lobsterin"
  vasper-makefile.zsh --lobsterin "POSCAR" "POTCAR" "$3"
  exit 0
fi

if [[ -n "${opthash[(i)--raw_data]}" ]]; then
  ##### $1: path to POSCAR
  ##### $2: tolerance parse to phonopy
  argnum_check "2" "$#"
  file_does_not_exist_check "raw_data"
  mkdir raw_data
  cp $1 raw_data
  POSCAR_ABSPATH=$(cd `dirname "$1"`; echo `pwd`/`basename "$1"`)
  echo "$POSCAR_ABSPATH"
  cd raw_data
  phonopy --symmetry -c="$POSCAR_ABSPATH" --tolerance="$2"
  touch "vasper.log"
  echo "# phonopy symmetry" | tee -a "vasper.log"
  echo "phonopy --symmetry -c=$1 --tolerance=$2" | tee -a "vasper.log"
  cd -
  exit 0
fi

if [[ -n "${opthash[(i)--relax]}" ]]; then
  ##### $1: relax conf file
  ##### $2: 'vasper_relax.dat'
  source $MODULE_DIR/incar.zsh
  argnum_check "2" "$#"
  source $1
  file_exists_check "$P_POSFILE"
  file_does_not_exist_check "$P_DIRNAME"
  if [ "$P_DIRNAME" = "" ]; then
    local FLAG=1
    echo "P_DIRNAME is vacant"
    echo "make temporary directory, rename at the last"
    P_DIRNAME=`mktemp -d`
  fi
  touch "vasper.log"
  echo "making $P_DIRNAME directory" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  mkdir -p $P_DIRNAME
  echo "coping POSFILE in  $P_DIRNAME directory" | tee -a "vasper.log"
  echo "POSCAR file : `pwd`/$P_POSFILE"
  echo "" | tee -a "vasper.log"
  cp $1 $P_DIRNAME
  cp $2 $P_DIRNAME
  cp $P_POSFILE $P_DIRNAME/POSCAR
  mv "vasper.log" $P_DIRNAME
  cp $1 $P_DIRNAME
  cd $P_DIRNAME

  echo "~~ making POTCAR ~~" | tee -a "vasper.log"
  echo "psudopotential : $P_PSP" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  vasper-makefile.zsh --potcar "default" "$P_PSP"

  echo "~~ making KPOINTS ~~" | tee -a "vasper.log"
  echo "sampling method : $P_KSAMP_METHOD" | tee -a "vasper.log"
  echo "sampling num : $P_KNUM" | tee -a "vasper.log"
  echo "shift : $P_KSHIFT" | tee -a "vasper.log"
  if [ "$P_KSAMP_METHOD" = "auto" ]; then
    echo "read bravais lattice, 'P_KSHIFT' setting will be ignored" | tee -a "vasper.log"
    vasper-makefile.zsh --kpoints "$P_KSAMP_METHOD" "$P_KNUM" "POSCAR"
  else
    vasper-makefile.zsh --kpoints "$P_KSAMP_METHOD" "$P_KNUM" "$P_KSHIFT"
  fi
  echo "" | tee -a "vasper.log"

  echo "~~ making INCAR ~~" | tee -a "vasper.log"
  echo "ENCUT  : $P_ENCUT"  | tee -a "vasper.log"
  echo "EDIFF  : $P_EDIFF"  | tee -a "vasper.log"
  echo "EDIFFG : $P_EDIFFG" | tee -a "vasper.log"
  echo "ISMEAR : $P_ISMEAR" | tee -a "vasper.log"
  echo "SIGMA  : $P_SIGMA"  | tee -a "vasper.log"
  echo "ISIF   : $P_ISIF"   | tee -a "vasper.log"
  vasper-makefile.zsh --incar_relax "$P_ENCUT" "$P_PSP"
  revise_incar_param "INCAR" "EDIFF" "$P_EDIFF"
  revise_incar_param "INCAR" "EDIFFG" "$P_EDIFFG"
  revise_incar_param "INCAR" "ISMEAR" "$P_ISMEAR"
  revise_incar_param "INCAR" "SIGMA" "$P_SIGMA"
  revise_incar_param "INCAR" "ISIF" "$P_ISIF"

  echo "~~ making job_relax.sh ~~" | tee -a "vasper.log"
  if [ "$FLAG" = 1 ]; then
    local KNUM=(`echo $P_KNUM`)
    local EC=`revise_encut "$P_ENCUT"`
    if [ "$P_ISMEAR" = -5 ]; then
      local ISMR='t'
    elif [ "$P_ISMEAR" = 0 ]; then
      local ISMR='g'
    else
      local ISMR='m'
    fi
    NEW_DIRNAME="${P_PSP}_`printf %02d $KNUM[1]``printf %02d $KNUM[2]``printf %02d $KNUM[3]`_${EC}_`printf %.2f ${P_SIGMA}`${ISMR}"
  fi
  if [ "$P_JOBNAME" = "" ]; then
    P_JOBNAME=${NEW_DIRNAME}_relax
  fi
  echo "job name : $P_JOBNAME" | tee -a "vasper.log"
  echo "" | tee -a "vasper.log"
  vasper-makefile.zsh --job "relax" "$P_JOBNAME"

  cd -
  if [ "$FLAG" = 1 ]; then
    echo "rename directory : $P_DIRNAME => $NEW_DIRNAME"
    file_does_not_exist_check "$NEW_DIRNAME"
    mv $P_DIRNAME $NEW_DIRNAME
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--relax_multi]}" ]]; then
  ##### $1: 'vasper_relax.conf'
  ##### $2: 'vasper_relax.dat'
  ##### $3: ENCUT    ex. "300 350 400 450"
  ##### $4: KPOINTS    ex. "10 10 8, 12 12 10, 14 14 10"
  ##### $5: SIGMA    ex. "0.05 0.1 0.2 0.3"
  argnum_check "5" "$#"
  for SGM in `echo $5`
  do
    for EN in `echo $3`
    do
      comma_num=`echo $4 | sed s/"[0-9 ]"//g`
      arr_num=$(($#comma_num+1))
      for i in {1..${arr_num}}
      do
        KP=`echo $4 | cut -f $i -d ","`
        vasper-makefile.zsh --revise_setting "$1" "P_ENCUT" "$EN"
        vasper-makefile.zsh --revise_setting "$1" "P_KNUM" "$KP"
        vasper-makefile.zsh --revise_setting "$1" "P_SIGMA" "$SGM"
        vasper-makefile.zsh --revise_setting "$1" "P_DIRNAME" ""
        vasper-makefile.zsh --revise_setting "$1" "P_JOBNAME" ""
        vasper-makedir.zsh --relax "$1" "$2"
      done
    done
  done
  exit 0
fi

if [[ -n "${opthash[(i)--static]}" ]]; then
  ##### $1: relax dirname
  ##### $2: static dirname
  argnum_check "2" "$#"
  file_exists_check "$1"
  file_does_not_exist_check "$2"
  source $MODULE_DIR/makejob.zsh
  source $MODULE_DIR/vasprun.zsh
  OPT_NUM=`cd $1; getoptnum`
  RELAX_DIR=$1/opt$OPT_NUM
  echo $RELAX_DIR
  JOBNAME=`get_jobname_from_file $1/job_relax.sh | sed s/"relax"/"static"/g`
  echo $RELAX_DIR
  echo "making $2 directory"
  echo "copying CONTCAR INCAR KPOINTS in $RELAX_DIR to static"
  mkdir -p $2
  cp $RELAX_DIR/CONTCAR $2/POSCAR
  cp $RELAX_DIR/POTCAR $RELAX_DIR/INCAR $RELAX_DIR/KPOINTS $2
  cd $2
  echo "makeing job_static.sh"
  vasper-makefile.zsh --job "static" "$JOBNAME"
  echo "revising INCAR"
  vasper-makefile.zsh --incar_static "INCAR"
  exit 0
fi

nothing_excuted
