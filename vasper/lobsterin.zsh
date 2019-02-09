#!/usr/bin/zsh

###############################################################################
# functions for making lobsterin file
###############################################################################

function autodistance()
{
  ##### $1 : POSCAR file
  ##### $2 : n th neighbor
  DISTANCES=(`$MODULE_DIR/poscar.py -c=POSCAR -d`)
  if [ "$2" -gt "$#DISTANCES" ]; then
    echo "You can specify less equal $#DISTANCES"
    exit 251
  fi
  DISTANCE=$(($DISTANCES[$2]+0.01))
  echo "! all pairs in a given distance range (in Angstrom, not in atomic units):" >> lobsterin
  echo "cohpGenerator from 0.01 to $DISTANCE orbitalwise" >> lobsterin
  echo "" >> lobsterin
}

function basisfunctions()
{
  ##### $1 : POTCAR file
  echo "! You can also specify the basis functions per element manually" >> lobsterin
  $MODULE_DIR/potcar.py -p "POTCAR" -o >> lobsterin
  echo "" >> lobsterin
}

function basisSet()
{
  ##### $1 : POTCAR file
  echo "! basisSet, you can choose 'Bunge', 'Koga' or 'pbeVaspFit2015'" >> lobsterin
  echo "basisSet pbeVaspFit2015" >> lobsterin
  echo "" >> lobsterin
}

function mk_detail_files()
{
  echo "! writeBasisFunctions" >> lobsterin
  echo "! writeMatricesToFile" >> lobsterin
  echo "" >> lobsterin
}

function lobsterin_template()
{
  echo "" >> lobsterin
  cat $TEMPLATE_DIR/lobsterin >> lobsterin
}
