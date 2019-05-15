source /home/mizo/.zshenv

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
