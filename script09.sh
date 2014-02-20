#!/bin/bash
#Encontrar UIDs duplicados

awk -F: 'uname [$3]++ && uname[$3] > 1 {print "duplicate user:", $1}' /etc/passwd
