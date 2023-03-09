#!/bin/bash
filesdir=$1
searchstr=$2
if [ $# -lt 2 ];
then
    echo "Not enough arguments."
    exit 1
fi

if [ -d "$filesdir" ];
then
	X=$(ls $filesdir | wc -l)
	Y=$(grep -r "$searchstr" "$filesdir" | wc -l)
	echo "The number of files are $X and the number of matching lines are $Y"
else
	echo "Error: filesdir is not a directory"
	exit 1
fi

