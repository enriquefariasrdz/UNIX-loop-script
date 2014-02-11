rm test001.txt
while read line
do
command=`ls $line`
echo -e "$command \n\n\n\n\n\n"
done<ls.txt
