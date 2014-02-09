echo "Please enter the file name:"

read file

echo "How many files?"

read n

touch $file{1..$n}.txt

echo $n $file "have been created"
