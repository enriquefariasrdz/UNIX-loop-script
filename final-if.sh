#!/bin/bash

env=$1



for uuid in `cat modsource.txt`;
do
echo $uuid
name=$(date +"%m_%d_%Y_%k%M")
/ms/dist/fiditoperations/PROJ/utils_optimus/prod/bin/log_finder_parallel.py --env $env  $uuid >>"$name-$$.txt"
done


if [ $# == 1 ]; then
echo "File name-$$.txt has been crated"
else
echo "****************************************Please check arguments******************************"
fi
