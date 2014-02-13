#!/bin/bash

env=$1



for uuid in `cat modsource.txt`;
do
echo $uuid
name=$(date +"%m_%d_%Y_%k%M")

if [ $# == 1 ]; then


/ms/dist/fiditoperations/PROJ/utils_optimus/prod/bin/log_finder_parallel.py --env $env  $uuid >>"$name-$$.txt"

echo "File $name-$$.txt has been crated"
else
echo "****************************************Please check environment arguments******************************"

fi

done
