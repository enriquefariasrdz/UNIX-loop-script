#!/bin/bash

env=$1



for uuid in `cat modsource.txt`;
do
echo $uuid
name=$(date +"%m_%d_%Y_%k%M")
if [[ $# == 1 ]] && [[ $1 == 'dev' || $1 == 'devhk' || $1 == 'devln' ||$1 == 'qa' || $1 == 'qaeds' || $1 == 'qahk' || $1 == 'qaln' || $1 == 'qatk' || $1 == 'bas' || $1 == 'bas2' || $1 == 'reg' || $1 == 'uat' || $1 == 'prod' || $1 == 'prodcredit' || $1 == 'prod2' || $1 == 'prod2genesis' || $1 == 'prod2hk' || $1 == 'prod2ln' || $1 == 'prod2tk' || $1 == 'prod2vi' ]] ; then


/MSscriptparallel.py --env $env  $uuid >>"$name-$$.txt"



echo "File $name-$$.txt has been crated"
else
echo "****************************************Please check environment arguments******************************"

fi

done
