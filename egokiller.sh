#!/bin/bash

function DEGO_CONTAINER_ID(){
clear
echo "Processing..."

umask 000

TEMPHSOUT=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPFS=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPDEGOCON=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPSS=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPEGOS=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPEGOID=$(mktemp /tmp/output.XXXXXXXXXX)
TEMPEGODITAILS=$(mktemp /tmp/output.XXXXXXXXXX)

        tmp1=`/ms/dist/unixops/bin/pssh -hostfile ~abdona/hostsDataBase.txt -mode 'ssh' -- "ps -ef | grep runRiceDriverEngine" | grep /tmp/pssh | awk '{print $3}'`
        egrep -v "grep|finished with status 0" "/$tmp1/log" > $TEMPHSOUT

        awk -v OFS="," '{print (substr($6,0,length($6)-1),$8,$10,$(NF-2),$NF);}' $TEMPHSOUT > $TEMPFS

        tmp2=`/ms/dist/unixops/bin/pssh -hostfile ~abdona/hostsDataBase.txt -mode 'ssh' -- "ps -ef | grep -i dego_container" | grep /tmp/pssh | awk '{print $3}'`
        egrep -v "grep|finished with status 0" "/$tmp2/log" > $TEMPDEGOCON


        awk -v OFS="," '{print ($9,substr($18,20));}' $TEMPDEGOCON > $TEMPSS

        while read line
        do
        ppid=`echo $line | cut -d"," -f3`
        grep $ppid ~abdona/secondStep.txt >> $TEMPEGOS

        done < $TEMPFS

        join --nocheck-order -t"," -1 3 -2 1 <(sort -t"," -n -k3 $TEMPFS) <(sort -t"," -n -k1 $TEMPEGOS) > $TEMPEGOID

        awk -F"," -v OFS="," -v status="" -v env1="$1"  -v env2="$2" '{ if ( $4 == env1 && $5 == env2 ){print ($1,$2,$3,$4,$5,$6); status = "true";}} END {if (status != "true"){print "No matches found!";}}' $TEMPEGOID > $TEMPEGODITAILS

        clear

        awk -F"," 'BEGIN{printf ("%-20s %-30s %-20s %-20s %-20s %-20s\n","PPID","HOSTNAME","PERSONALITY","ENVIRONMENT","TYPE","EGO ACTIVITY\n")}{printf ("%-20s %-30s %-20s %-20s %-20s %-20s\n",$1,$2,$3,$4,$5,$6);}' $TEMPEGODITAILS
}


function BOUNCER(){
bounce="$1"
        if [ "$bounce" == "yes" ] || [ "$bounce" == "y" ] || [ "$bounce" == "YES" ] || [ "$bounce" == "Y" ]
        then
                        ~abdona/Bouncer.sh "$TEMPEGODITAILS"
        else
                echo "exiting...2"
                exit
    fi

}
function NotEmptyArgs(){
arg1="$1"
arg2="$2"

        if [ -z "$arg1" ] && [ -z "$arg2" ]
        then
                echo -e "Usage: <script> <enviroment> <type> \ne.g. script.sh reg eod"
        else
                DEGO_CONTAINER_ID "$1" "$2"
        fi
}
function ReadyToBounce(){
bounce="$1"
        if [ -s $TEMPEGODITAILS ]
        then
                if grep -qw "No matches found!" < $TEMPEGODITAILS
                then

                        echo "exiting...1"
                        exit
                else
                        echo -n 'Ready to bounce? [YES/NO]'
                        read -e bounce
                        BOUNCER "$bounce"
                fi
        else
                echo "can't execute the Bouncer"
                exit
        fi
}

if [ -s Bouncer.sh ]
then
        if [ "$#" -eq 2 ]
        then
                bounce=""
                NotEmptyArgs "$1" "$2"
                echo
                echo -e "log data could be found in:\n\n$TEMPHSOUT\n$TEMPFS\n$TEMPDEGOCON\n$TEMPSS\n$TEMPEGOS\n$TEMPEGOID\n$TEMPEGODITAILS\n"
                ReadyToBounce "$bounce"
        else
                echo -e "Usage: <script> <enviroment> <type> \ne.g. script.sh reg eod"
                exit
        fi
else
        PWD=`pwd`
        echo "Unable to locate Bouncer.sh file in: $PWD"
