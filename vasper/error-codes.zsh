#!/usr/bin/zsh

###############################################################################
# make various error codes
###############################################################################

### nothing was excuted
function nothing_excuted()
{
  {
    echo "nothing was excuted"
    echo "please check usage : $(basename ${0}) -h"
    echo "exit(255)"
    exit 255
  }
}

### check the number of argments
function argnum_check()
{
  ##### $1: expected argments number
  ##### $2: actual argments number
  if [ "$1" != "$2" ]; then
    {
      echo "The number of argments is different from expected."
      echo "expected argment number : $1"
      echo "actual argment number : $2"
      echo "exit(254)"
      exit 254
    }
  fi
}

### check file does not exist
function file_does_not_exist_check()
{
  ##### $1: check filename
  if [ -e "$1" ]; then
    echo "file exists : $1"
      echo "exit(253)"
    exit 253
  fi
}

### check file exists
function file_exists_check()
{
  ##### $1: check filename
  if [ ! -e "$1" ]; then
    echo "file does not exist : $1"
    echo "exit(252)"
    exit 252
  fi
}

### check keys of args
function unexpected_args()
{
  ##### $1: unexpected_argment
  echo "unexpected argments parsed : $1"
  echo "exit(251)"
  exit 251
}
