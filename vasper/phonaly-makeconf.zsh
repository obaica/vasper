#!/usr/bin/zsh

################################################################################
# make various conf file
################################################################################

### variables


### fuctions
function usage() {
  cat <<EOF
  "g-makeconf.zsh" makes various conf files

  Options:
    -h           print usage

    --disp_conf  make band.conf
        \$1: the number of displacement  ex) "3 3 3"

    --band_conf  make band.conf

    --dos_conf   make dos.conf
        \$1: the number of mesh  ex) "13 13 13"

    --pdos_conf  make pdos.conf
        \$1: the number of mesh  ex) "13 13 13"

    --fchdf_conf make kappa-mxxxxxx.conf

    --kappa_conf make kappa-mxxxxxx.conf
        \$1: the number of mesh  ex) "13 13 13"

    --post_conf make conf files needed in the post process

    --qpoints_conf make qpoints.conf

    --mesh return mesh
        \$1: "crude" or "normal" or "accurate"

    --run run automatically
        \$1: "crude" or "normal" or "accurate"


EOF
}


function mk_disp_conf()
{
  ### $1: the number of displacement  ex) "3 3 3"
  echo "CREATE_DISPLACEMENTS = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
  echo "DIM = $1"
}


function mk_band_conf()
{
  grep DIM disp_fc2.conf
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --band
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --band_label
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "NAC = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
}


function mk_dos_pdos_conf()
{
  ##### $1: dos or pdos
  ##### $2: the number of mesh
  grep DIM disp_fc2.conf
  if [ ! $2 = "" ]; then
    echo "MESH = $2"
  fi
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "GAMMA_CENTER = .TRUE."
  echo "GROUP_VELOCITY = .TRUE."
  echo "NAC = .TRUE."
  echo "TETRAHEDRON = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
  if [ $1 = "dos" ]; then
    echo "DOS = .TRUE."
    echo "MESH_FORMAT = HDF5"
  elif [ $1 = "pdos" ]; then
    poscry-phonoconf.py --posfile="POSCAR-unitcell" --pdos
    echo "WRITE_MESH = .FALSE."
  else
    echo "\$2 does not set"
    exit 1
  fi
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
  echo "CELL_FILENAME = POSCAR-unitcell"
}


function mk_kappa_conf()
{
  ##### $1: the number of mesh
  grep DIM disp_fc3.conf
  grep DIM disp_fc2.conf | sed s/"DIM"/"DIM_FC2"/g
  if [ ! $1 = "" ]; then
    echo "MESH = $1"
  fi
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "BTERTA = .TRUE."
  echo "NAC = .TRUE."
  echo "READ_FC2 = .TRUE."
  echo "READ_FC3 = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
  echo "FULL_PP = .TURE.  # bug: no response"
}

function mk_qpoints_conf()
{
  grep DIM disp_fc2.conf
  poscry-phonoconf.py --posfile="POSCAR-unitcell" --prim
  echo "GAMMA_CENTER = .TRUE."
  echo "GROUP_VELOCITY = .TRUE."
  echo "NAC = .TRUE."
  echo "CELL_FILENAME = POSCAR-unitcell"
  echo "QPOINTS = .TRUE."
  }

### zparseopts
local -A opthash
zparseopts -D -A opthash -- h -disp_conf -band_conf -dos_conf -pdos_conf \
  -fchdf_conf -kappa_conf -mesh -post_conf -run -qpoints_conf

if [[ -n "${opthash[(i)-h]}" ]]; then
  usage
  exit 0
fi

if [[ -n "${opthash[(i)--disp_conf]}" ]]; then
  ### $1: the number of displacement  ex) "3 3 3"
  mk_disp_conf $1
  exit 0
fi

if [[ -n "${opthash[(i)--band_conf]}" ]]; then
  mk_band_conf
  exit 0
fi

if [[ -n "${opthash[(i)--dos_conf]}" ]]; then
  mk_dos_pdos_conf "dos" $1
  exit 0
fi

if [[ -n "${opthash[(i)--pdos_conf]}" ]]; then
  mk_dos_pdos_conf "pdos" $1
  exit 0
fi

if [[ -n "${opthash[(i)--fchdf_conf]}" ]]; then
  mk_fchdf_conf
  exit 0
fi

if [[ -n "${opthash[(i)--kappa_conf]}" ]]; then
  mk_kappa_conf $1
  exit 0
fi

if [[ -n "${opthash[(i)--post_conf]}" ]]; then
  mk_band_conf > band.conf
  mk_dos_pdos_conf "dos" > dos-m.conf
  mk_dos_pdos_conf "pdos" > pdos-m.conf
  mk_fchdf_conf > fc-hdf.conf
  mk_kappa_conf > kappa-m.conf
  exit 0
fi

if [[ -n "${opthash[(i)--mesh]}" ]]; then
  ### $1: 'crude' or 'normal' or 'accurate'
  $(dirname $(dirname ${0}))/phonaly/writemesh.py $1 $2
  exit 0
fi

if [[ -n "${opthash[(i)--run]}" ]]; then
  ### $1: 'crude' or 'normal' or 'accurate'
  MESH=`$(dirname $(dirname ${0}))/phonaly/writemesh.py $1 $2`
  if [ ! $? = 0 ]; then
    echo "Arguments are not set correctly."
    exit 1
  fi
  phonopy band.conf --mesh="$MESH"
  phonopy dos-m.conf --mesh="$MESH"
  phonopy pdos-m.conf --mesh="$MESH"
  phono3py fc-hdf.conf
  phono3py kappa-m.conf --mesh="$MESH" --full-pp
  exit 1
fi

if [[ -n "${opthash[(i)--qpoints_conf]}" ]]; then
  mk_qpoints_conf $1
  exit 0
fi

echo "nothing was executed. check the usage  =>  $(basename ${0}) -h"
exit 1
