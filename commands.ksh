#!/bin/ksh
file="commands.txt"
while read line
do
        cat commands.txt
        echo "$line"
done <"$file"
