#!/bin/bash

if [ $# -eq 0 ]; then
echo >&2 "Usage: jstackSeries <pid> <<count> delay> "
echo >&2 "    Defaults: count = 3, delay = 0.5 (seconds)"
   exit 1
fi
pid=$1          # required
count=${2:-3}  # defaults to 3 times
delay=${3:-0.5} # defaults to 0.5 seconds
while [ $count -gt 0 ]
do
     jmap -histo:live $pid > /tmp/histo.$pid.$count
     sleep $delay
     let count--
     echo -n "."
done
