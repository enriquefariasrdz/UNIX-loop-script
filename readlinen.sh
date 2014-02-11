#!/bin/bash

while read line

do

        ls $line
        echo -e "\n\n\n\n"


done<ls.txt
