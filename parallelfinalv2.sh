#!/bin/bash

env=$1

source=$2

name=$(date +"%m_%d_%Y_%k%M")
path1="/v/global/user/e/en/enriquef/proyect1/logs/"
fn=${path1}.${name}
if [[ $# == 2 ]] && [[ $1 == 'dev' || $1 == 'devhk' || $1 == 'devln' || $1 == 'qa' || $1 == 'qaeds' || $1 == 'qahk' || $1 == 'qaln' || $1 == 'qatk' || $1 == 'bas' || $1 == 'bas1' || $1 == 'reg' || $1 == 'uat' || $1 == 'prod' || $1 == 'prodcredit' || $1 == 'prod2' || $1 == 'prod2genesis' || $1 == 'prod2hk' || $1 == 'prod2ln' || $1 == 'prod2tk' || $1 == 'prod2vi' ]] ; then


for uuid in `cat $source`;
do
echo $uuid

/ms/dist/fiditoperations/PROJ/utils_optimus/prod/bin/log_finder_parallel.py --env $env $uuid >>"$fn-$$.txt"

done

echo "                    You may find find the result on the following path: $fn-$$.txt                                            "
else
echo "****************************************Please check environment arguments******************************"

fi
