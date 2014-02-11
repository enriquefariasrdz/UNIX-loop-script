while read line

do

command=`$line`

echo -e "$command \n"

done<listcommands.txt
