#!/usr/bin/zsh

###############################################################################
# make various files used in VASP calculation
###############################################################################

### usage
function usage()
{
  cat <<EOF
  This file makes various files used in VASP calculation.

  Options:

    -h evoke function usage

    --disp_file    make displaced files
        \$1: conf file

    --force_sets    make FORCE_SETS file
        \$1: 'alm'

    --get_conf      make conf file
        \$1: 'vasper_fc2'
        \$1: 'vasper_relax'
        \$1: 'vasper_alm'
        \$1: 'disp_fc2' \$2: dimension(ex. "3 3 3" )
        \$1: 'disp_alm' \$2: dimension(ex. "3 3 3" ) \$3: temperature \$4: the number of displacements
        \$1: 'dos' \$2: disp.conf file \$3: mesh

    --incar_relax   make INCAR for relax
        if ENCUT is less than 10, automatically read 'POTCAR' for extructing ENMAX and ENCUT=ENMAX*ENCUT
        \$1: ENCUT
        \$2: GGA, ex. "PBEsol"

    --incar_band    make INCAR for band structure
        \$1: INCAR file used in relax

    --incar_born    make INCAR for BORN
        \$1: INCAR file used in relax

    --incar_dos     make INCAR for dos
        \$1: INCAR file used in relax

    --incar_fc2     make INCAR for fc2
        \$1: INCAR file used in relax

    --incar_lobster    make INCAR for dos
        \$1: INCAR file used in relax
        \$1: vasprun.xml file used in relax
        \$2: POSCAR file
        \$3: POTCAR file

    --job           make job.sh
        \$1: run mode 'relax' 'alm' 'band' 'born' 'dos' 'fc2' 'lobster'
        \$2: jobname

    --kpoints       make KPOINTS
        \$1: run mode 'Monkhorst' or 'Gamma' or 'band' or 'auto'
                 if 'auto', bravais lattice = hexagonal => Gamma
                                    else                => Monkhorst
        \$2: kpoints 'Monkhorst' or 'Gamma' , ex. "6 6 6"
                     'band' , ex. 100
        \$3: 'Monkhorst' or 'Gamma' => shift, ex. "0 0 0"
             'band' or 'auto' => posfile, ex. "POSCAR"

    --kpoints_multi    make KPOINTS
        \$1: kptfile, ex. "KPOINTS"
        \$2: multiply, ex. "0.5"

    --kpoints_newmesh  make KPOINTS
        \$1: kptfile, ex. "KPOINTS"
        \$2: new mesh, ex. "3 3 3"

    --lobsterin     make lobsterin
        \$1: posfile
        \$2: potfile
        \$3: n th distance

    --potcar        make job.sh
        automatically read POSCAR to extract elements
        \$1: run mode 'default'
        \$2: psp "LDA" or "PBE" or "PBEsol"

    --remove_setting    remove conf or INCAR setting
        \$1: filename (support filetype : *.conf , INCAR)
        \$2: variable name

    --revise_setting    revise conf or INCAR setting
        if cannot find 'variable name', make new line
        \$1: filename (support filetype : *.conf , INCAR)
        \$2: variable name
        \$3: revise name

  Exit:
    0   : normal
    1   : unexpected error

    255 : Nothing was excuted.
    254 : The number of argments were different from expected.
    253 : The file you tried to make already exists.
    252 : The file which needs to process does not exist.
    251 : Unexpected argments were parsed.

EOF
}

### envs
source $HOME/.vasperrc

### error codes
source $MODULE_DIR/error-codes.zsh

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h \
           -get_conf \
           -force_sets \
           -incar_band \
           -incar_born \
           -incar_dos \
           -incar_fc2 \
           -incar_lobster \
           -incar_relax \
           -job \
           -kpoints \
           -kpoints_newmesh \
           -kpoints_multi \
           -lobsterin \
           -potcar \
           -remove_setting \
           -revise_setting

### option
if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--disp]}" ]]; then
  ##### $1: filetype 'fc2'
  ##### $2: dim ex. "3 3 3"
  file_does_not_exist_check "disp_${1}.conf"
  disp_conf "$1" "$2"
  exit 0
fi

if [[ -n "${opthash[(i)--force_sets]}" ]]; then
  ##### $1: 'alm'
  if [ "$1" = "alm" ]; then
    # conda activate $ALM_ENV
    $MODULE_DIR/alm-phonopy.py -f --vasprun="`echo disp-*/vasprun.xml`"
    # conda deactivate
  else
    unexpected_args "$1"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--get_conf]}" ]]; then
  ##### $1: 'vasper_fc2'
  ##### $1: 'vasper_relax'
  ##### $1: 'vasper_alm'
  ##### $1: 'disp_fc2' $2: dimension(ex. "3 3 3" )
  ##### $1: 'disp_conf' $2: dimension(ex. "3 3 3" ) $3: temperature $4: sampling num
  ##### $1: 'dos' $2: disp.conf file $3: mesh
  source $MODULE_DIR/conf.zsh
  file_does_not_exist_check "${1}.conf"
  if [ "$1" = "vasper_relax" ]; then
    argnum_check "1" "$#"
    cp $TEMPLATE_DIR/${1}.conf ./${1}.conf
  elif [ "$1" = "vasper_fc2" ]; then
    argnum_check "1" "$#"
    cp $TEMPLATE_DIR/${1}.conf ./${1}.conf
  elif [ "$1" = "vasper_alm" ]; then
    argnum_check "1" "$#"
    cp $TEMPLATE_DIR/${1}.conf ./${1}.conf
  elif [ "$1" = "disp_fc2" ]; then
    argnum_check "2" "$#"
    disp_conf "fc2" "$2"
  elif [ "$1" = "disp_alm" ]; then
    argnum_check "4" "$#"
    disp_conf "alm" "$2" "$3" "$4"
  elif [ "$1" = "dos" ]; then
    argnum_check "3" "$#"
    dos_pdos_conf "$1" "$2" "$3"
  else
    unexpected_args $1
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--incar_band]}" ]]; then
  ##### $1: INCAR file used in relax
  source $MODULE_DIR/incar.zsh
  argnum_check "1" "$#"
  file_exists_check "$1"
  mk_incar_band "$1"
  exit 0
fi

if [[ -n "${opthash[(i)--incar_born]}" ]]; then
  ##### $1: INCAR file used in relax
  source $MODULE_DIR/incar.zsh
  argnum_check "1" "$#"
  file_exists_check "$1"
  mk_incar_born "$1"
  exit 0
fi

if [[ -n "${opthash[(i)--incar_dos]}" ]]; then
  ##### $1: INCAR file used in relax
  source $MODULE_DIR/incar.zsh
  argnum_check "1" "$#"
  file_exists_check "$1"
  mk_incar_dos "$1"
  exit 0
fi

if [[ -n "${opthash[(i)--incar_fc2]}" ]]; then
  ##### $1: INCAR file used in relax
  source $MODULE_DIR/incar.zsh
  argnum_check "1" "$#"
  file_exists_check "$1"
  mk_incar_fc2 "$1"
  exit 0
fi

if [[ -n "${opthash[(i)--incar_lobster]}" ]]; then
  ##### $1: INCAR file used in relax
  ##### $2: vasprun.xml file used in relax
  ##### $3: POSCAR file
  ##### $4: POTCAR file
  source $MODULE_DIR/incar.zsh
  argnum_check "4" "$#"
  file_exists_check "$1"
  file_exists_check "$2"
  file_exists_check "$3"
  file_exists_check "$4"
  mk_incar_lobster "$1" "$2" "$3" "$4"
  exit 0
fi

if [[ -n "${opthash[(i)--incar_relax]}" ]]; then
   ##### $1: ENCUT
   ##### $2: GGA, if "PBEsol" then GGA = PS
  source $MODULE_DIR/incar.zsh
  argnum_check "2" "$#"
  file_does_not_exist_check "INCAR"
  file_exists_check "POTCAR"
  mk_incar_relax "$1" "$2"
  exit 0
fi

if [[ -n "${opthash[(i)--job]}" ]]; then
  ##### $1: run mode
  ##### $2: jobname
  source $MODULE_DIR/makejob.zsh
  argnum_check "2" "$#"
  if [ "$1" = "relax" ]; then
    touch "job_relax.sh"
    job_header $2 >> "job_relax.sh"
    echo "" >> "job_relax.sh"
    vasprun_command >> "job_relax.sh"
  elif [ "$1" = "alm" ]; then
    touch "job_alm.sh"
    job_header $2 >> "job_alm.sh"
    echo "" >> "job_alm.sh"
    vasprun_command >> "job_alm.sh"
  elif [ "$1" = "band" ]; then
    touch "job_band.sh"
    job_header $2 >> "job_band.sh"
    echo "" >> "job_band.sh"
    static_calc >> "job_band.sh"
  elif [ "$1" = "born" ]; then
    touch "job_born.sh"
    job_header $2 >> "job_born.sh"
    echo "" >> "job_born.sh"
    vasprun_command >> "job_born.sh"
  elif [ "$1" = "dos" ]; then
    touch "job_dos.sh"
    job_header $2 >> "job_dos.sh"
    echo "" >> "job_dos.sh"
    static_calc >> "job_dos.sh"
  elif [ "$1" = "fc2" ]; then
    touch "job_fc2.sh"
    job_header $2 >> "job_fc2.sh"
    echo "" >> "job_fc2.sh"
    vasprun_command >> "job_fc2.sh"
  elif [ "$1" = "lobster" ]; then
    touch "job_lobster.sh"
    job_header $2 >> "job_lobster.sh"
    echo "" >> "job_lobster.sh"
    static_calc >> "job_lobster.sh"
    echo "" >> "job_lobster.sh"
    lobster_command >> "job_lobster.sh"
  else
    unexpected_args "$1"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--kpoints]}" ]]; then
  ##### $1: run mode 'Monkhorst' or 'Gamma' or 'band'
  #####        if 'auto', bravais lattice = hexagonal => Gamma
  #####                           else                => Monkhorst
  ##### $2: kpoints 'Monkhorst' or 'Gamma' , ex. "6 6 6"
  #####             'band' , ex. 100
  ##### $3: 'Monkhorst' or 'Gamma' => shift, ex. "0 0 0"
  #####     'band' or 'auto' => posfile, ex. "POSCAR"
  argnum_check "3" "$#"
  file_does_not_exist_check "KPOINTS"
  if [ "$1" = "band" ]; then
    $MODULE_DIR/kpoints.py --style="$1" --knum="$2" -c="$3"
  elif [ "$1" = "auto" ]; then
    BRAVAIS=`$MODULE_DIR/poscar.py -c="$3" -b`
    echo "bravais : $BRAVAIS"
    if [ "$BRAVAIS" = "hexagonal" ]; then
      echo "Sampling method : 'Gamma'"
      $MODULE_DIR/kpoints.py --style="Gamma" --kpts="$2" --shift="0 0 0"
    else
      echo "Sampling method : 'Monkhorst'"
      $MODULE_DIR/kpoints.py --style="Monkhorst" --kpts="$2" --shift="0 0 0"
    fi
  else
    $MODULE_DIR/kpoints.py --style="$1" --kpts="$2" --shift="$3"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--kpoints_newmesh]}" ]]; then
  ##### $1: kptfile, ex. "KPOINTS"
  ##### $2: new mesh, ex. "3 3 3"
  argnum_check "2" "$#"
  file_exists_check "$1"
  echo "revise the number of mesh => $1"
  $MODULE_DIR/kpoints.py --style="revise" -k="$1" --kpts="$2"
  echo ""
  echo "~~ revised KPOINTS ~~"
  cat KPOINTS
  exit 0
fi

if [[ -n "${opthash[(i)--kpoints_multi]}" ]]; then
  ##### $1: kptfile, ex. "KPOINTS"
  ##### $2: multiply, ex. "0.5"
  argnum_check "2" "$#"
  file_exists_check "$1"
  echo "multiply (x$2) kpts in $1"
  $MODULE_DIR/kpoints.py --style="revise" -k="$1" --multiply="$2"
  echo ""
  echo "~~ revised KPOINTS ~~"
  cat KPOINTS
  exit 0
fi

if [[ -n "${opthash[(i)--lobsterin]}" ]]; then
  ##### $1: posfile
  ##### $2: potfile
  ##### $3: n th distance
  source $MODULE_DIR/lobsterin.zsh
  argnum_check "3" "$#"
  file_exists_check "$1"
  file_exists_check "$2"
  file_does_not_exist_check "lobsterin"
  basisfunctions "$2"
  autodistance "$1" "$3"
  mk_detail_files
  lobsterin_template
  exit 0
fi

if [[ -n "${opthash[(i)--potcar]}" ]]; then
  ##### $1: run mode "default"
  ##### $2: psp "LDA" or "PBE"
  argnum_check "2" "$#"
  file_does_not_exist_check "POTCAR"
  file_exists_check "POSCAR"
  source $MODULE_DIR/potcar.zsh
  if [ "$1" = "default" ]; then
    make_default_potcar_from_poscar "POSCAR" "$2"
    if [ "$?" = "252" ]; then
      exit 252
    fi
  else
    unexpected_args "$1"
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--remove_setting]}" ]]; then
  ##### $1: filename (support filetype : *.conf , INCAR)
  ##### $2: variable name
  argnum_check "2" "$#"
  file_exists_check "$1"
  if [ "$1" = "INCAR" ]; then
    source $MODULE_DIR/incar.zsh
    make_new_incar_line_when_not_found "$1" "$2" "$3"
  elif `echo "$1" | grep -q ".conf"` ; then
    source $MODULE_DIR/conf.zsh
    remove_conf_setting "$1" "$2"
  else
    unexpected_args $1
  fi
  exit 0
fi

if [[ -n "${opthash[(i)--revise_setting]}" ]]; then
  ##### $1: filename (support filetype : *.conf , INCAR)
  ##### $2: variable name
  ##### $3: revise name
  argnum_check "3" "$#"
  file_exists_check "$1"
  if [ "$1" = "INCAR" ]; then
    source $MODULE_DIR/incar.zsh
    make_new_incar_line_when_not_found "$1" "$2" "$3"
  elif `echo "$1" | grep -q ".conf"` ; then
    source $MODULE_DIR/conf.zsh
    make_new_conf_line_when_not_found "$1" "$2" "$3"
  else
    unexpected_args $1
  fi
  exit 0
fi

nothing_excuted
