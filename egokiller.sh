#!/bin/bash

function DEGO_CONTAINER_ID(){

        clear
        umask 000
        hostlist="$3"

        #temp random files
        TEMPHSOUT=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPFS=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPDEGOCON=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPSS=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPEGOS=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPEGOID=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)
        TEMPEGODITAILS=$(mktemp /tmp/dego_bouncer.XXXXXXXXXX)

        #sending parallel commands seeking for runRiceDriverEngine process
        tmp1=`/ms/dist/unixops/bin/pssh -hostfile $hostlist -mode 'ssh' -- "ps -ef | grep runRiceDriverEngine" | grep /tmp/pssh | awk '{print $3}'`

        #cleaning log and assigning output to TEMPHSOUT
        egrep -v "grep|finished with status 0" "/$tmp1/log" > $TEMPHSOUT

        #CSV hosts detail list running  runRiceDriverEngine process
        awk -v OFS="," '{print (substr($6,0,length($6)-1),$8,$10,$(NF-2),$NF);}' $TEMPHSOUT > $TEMPFS

        #sending parallel commands seeking for dego_containers
        tmp2=`/ms/dist/unixops/bin/pssh -hostfile $hostlist -mode 'ssh' -- "ps -ef | grep -i dego_container" | grep /tmp/pssh | awk '{print $3}'`

        #cleaning log and assigning output to TEMPDEGOCON
        egrep -v "grep|finished with status 0" "/$tmp2/log" > $TEMPDEGOCON


        #CSV hosts detail list displaying dego_containers
        awk -v OFS="," '{print ($9,substr($18,20));}' $TEMPDEGOCON > $TEMPSS

        #crossing runRiceDriverEngine against dego_container assigning output to TEMPFS
        while read line
        do
        ppid=`echo $line | cut -d"," -f3`
        grep $ppid $TEMPSS >> $TEMPEGOS

        done < $TEMPFS

        #joining runRiceDriverEngine with their respective dego_containers
        join --nocheck-order -t"," -1 3 -2 1 <(sort -t"," -n -k3 $TEMPFS) <(sort -t"," -n -k1 $TEMPEGOS) > $TEMPEGOID

        #filtering dego_containers based on the given arguments $1,$2
        awk -F"," -v OFS="," -v status="" -v env1="$1"  -v env2="$2" '{ if ( $4 == env1 && $5 == env2 ){print ($1,$2,$3,$4,$5,$6); status = "true";}} END {if (status != "true"){print "No matches found!";}}' $TEMPEGOID > $TEMPEGODITAILS

        clear

        #displaying formatted output for further user interact
        awk -F"," 'BEGIN{printf ("%-20s %-30s %-20s %-20s %-20s %-20s\n","PPID","HOSTNAME","PERSONALITY","ENVIRONMENT","TYPE","EGO ACTIVITY\n")}{printf ("%-20s %-30s %-20s %-20s %-20s %-20s\n",$1,$2,$3,$4,$5,$6);}' $TEMPEGODITAILS
}

function NotEmptyArgs(){

        env="$1"
        type="$2"
        hostlist="$3"

        if [ -z "$env" ] #checking if env variable is not empty
        then
                echo -e "Unable to read environment\nUsage: <script> <environment> <type> <hostlist> \ne.g. script.sh reg eod hostlist.txt..1"
                exit
        elif [ -z "$type" ] #checking if type variable is not empty
        then
                echo -e "Unable to read type\nUsage: <script> <environment> <type> <hostlist> \ne.g. script.sh reg eod hostlist.txt..2"
                exit
        elif [ -s "$hostlist" ] #checking if hostlist file exists and not empty
        then
                DEGO_CONTAINER_ID $env $type $hostlist #initializing DEGO_CONTAINER_ID function
        else
                echo -e "Unable to locate hostlist in: $PWD\nUsage: <script> <environment> <type> <hostlist> \ne.g. script.sh reg eod hostlist.txt"
                exit
        fi
}
function ReadyToBounce(){

        bounce="$1"

        if [ -s "$TEMPEGODITAILS" ] #checking if TEMPEGODITAILS file exists and not empty
        then
                if grep -qw "No matches found!" < $TEMPEGODITAILS #seeking for No matches string to exit the program
                then
                        echo "exiting...1"
                        exit
                else
                        echo -n 'Ready to bounce? [YES/NO]'
                        read -e bounce
                        #Validating yes,y,YES,YES
                        if [ "$bounce" == "yes" ] || [ "$bounce" == "y" ] || [ "$bounce" == "YES" ] || [ "$bounce" == "Y" ]
                        then
                                Bouncer.sh "$TEMPEGODITAILS"
                        else
                                #exiting if string don't match
                                echo "exiting...2"
                        exit
                        fi
                fi
        else
                echo "can't execute the Bouncer"
                exit
        fi
}

if [ -s Bouncer.sh ]
then
        if [ "$#" -eq 3 ] #checking if Bouncer.sh file exists and not empty
        then
                bounce=""
                NotEmptyArgs "$1" "$2" "$3" #initializing NotEmptyArgs function
                echo
                echo -e "log data could be found in:\n\n$TEMPHSOUT\n$TEMPFS\n$TEMPDEGOCON\n$TEMPSS\n$TEMPEGOS\n$TEMPEGOID\n$TEMPEGODITAILS\n"
                ReadyToBounce "$bounce"
        else
                echo -e "Usage: <script> <environment> <type> <hostlist> \ne.g. script.sh reg eod hostlist.txt"
                exit
        fi
else
        PWD=`pwd`
        echo "Unable to locate Bouncer.sh file in: $PWD"
