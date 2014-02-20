#!/bin/bash
#7 campos del archivo /etc/passwd utilizando while loop y IFS como separador

while IFS=: read -r f1 f2 f3 f4 f5 f6 f7
do echo "El usuario $f1 con shell $f7 y esta almacenado en el directorio $f6"
done</etc/passwd
