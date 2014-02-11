#!/bin/ksh
file="/home/user/1.txt"
# while loop
while read line
do
        # display line or do somthing on $line
        exec "$line"
done <"$file"
