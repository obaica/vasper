#$ -S /bin/zsh
#$ -cwd
#$ -N twin_Ti_relax
#$ -pe mpi* 16
#$ -e err.log
#$ -o std.log

ulimit -u unlimited
source /home/mizo/.zshenv

# export LD_LIBRARY_PATH=:/opt/intel/lib/intel64
# 
# export PATH="$HOME/github/vasper/scripts:$PATH"
# export PATH="$HOME/github/crystal/scripts:$PATH"
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# export PATH="$PYENV_ROOT/versions/anaconda3-5.3.1/bin/:$PATH"
source /home/mizo/.pyenv/versions/anaconda3-5.3.1/etc/profile.d/conda.sh

# echo $HOME
# source $HOME/.zshenv
conda activate relax
source $HOME/github/vasper/vasper/vasprun.zsh
source $HOME/github/vasper/vasper/error-codes.zsh

checkfiles
CURRENT_OPTNUM=`getoptnum`
if [ "$CURRENT_OPTNUM" = 0 ]; then
  MAKE_OPTNUM=1
else
  MAKE_OPTNUM=$CURRENT_OPTNUM
fi

for _ in {1..20}
do
  repeat_setting $MAKE_OPTNUM
  makeoptdir $MAKE_OPTNUM
  cd opt${MAKE_OPTNUM}
  run $MAX_REPEAT
  cd -
  echo "calc opt$OPTNUM has finished"
  
  # check all calculations have finished
  MAKE_OPTNUM=$(($MAKE_OPTNUM+1))
  if [ "`grep opt${MAKE_OPTNUM} vasper_relax.dat`" = "" ]; then
    echo "finish all opt[num] calculations"
    exit 0
  fi
done



