x=1
while 
((x<10))
do
	echo loop $x; ls > list.$x
	((x=x+1))
done
