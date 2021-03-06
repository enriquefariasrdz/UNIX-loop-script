#!/bin/bash -l

. /etc/systemvars.ksh
MODULEPATH=/mspath/etc/modules
export USE64BITJVM=1
module load msjava/sunjdk/1.6.0_31

if [ $# -eq 0 ]; then
    echo >&2 "Usage: jstacki <pid> <count> <delay> "
    echo >&2 "    Defaults: count = 3, delay = 0.5 (seconds)"
    exit 1
fi
pid=$1          # required
count=${2:-3}  # defaults to 3 times
delay=${3:-0.5} # defaults to 0.5 seconds
while [ $count -gt 0 ]
do
     jstack -l $pid >/tmp/jstack.$pid.$count
    sleep $delay
    let count--
    echo -n "."
done
