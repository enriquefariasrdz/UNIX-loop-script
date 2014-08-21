for num in {3..20..3}
do 
	modul=$(( num % 2 ))
	if [ $modul -eq 0 ]
	then
	echo "This is an even number $num"
	fi
done
