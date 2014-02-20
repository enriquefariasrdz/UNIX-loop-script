#!/bin/bash
#Encuentra los UIDs que tienen valor 0
awk -F: '$1=/pirate/{print "ID Encontrado, es "$1}' /etc/passwd
