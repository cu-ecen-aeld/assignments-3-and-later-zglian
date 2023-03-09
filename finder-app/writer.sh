#!/bin/bash

writefile=$1
writestr=$2

if [ $# -lt 2 ];
then
    echo "Not enough arguments."
    exit 1
else
	mkdir -p "$(dirname "$writefile")" && echo "$writestr" > $writefile
fi

if [ ! -f "$writefile" ];
then
	echo "Error: Could not creat file $writefile"
	exit 1
fi
