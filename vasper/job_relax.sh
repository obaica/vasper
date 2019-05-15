#$ -S /bin/zsh
#$ -cwd
#$ -N twin_Ti_relax
#$ -pe mpi* 16
#$ -e err.log
#$ -o std.log

ulimit -u unlimited

export LD_LIBRARY_PATH=:/opt/intel/lib/intel64

source $HOME/.zshenv
conda activate relax
source $HOME/github/vasper/vasper/vasprun.zsh

checkfiles
OPTNUM=`getoptnum`
for _ in {1..20}
do
  repeat_setting $OPTNUM
  makeoptdir
  echo "MAX_REPEAT : $MAX_REPEAT"
  run $MAX_REPEAT

  # check all calculations have finished
  OPTNUM=`getoptnum`
  if [ "`grep opt{$OPTNUM}`" = "" ]; then
    echo "finish all opt[num] calculations"
    exit 0
  fi
done
