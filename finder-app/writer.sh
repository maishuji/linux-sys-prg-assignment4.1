#!/bin/bash

writefile=$1;
writestr=$2;

if [ "$#" -ne 2 ]; then
    echo "Wrong number of args. Expected : 2, actual : $#"
    echo "Expected parameters : (1) file directory, (2) Search string"
    exit 1
fi

CHECKDIR=$( dirname "$writefile" )
echo ${CHECKDIR}

# Create directory if does not exist already
ERROR=$( { mkdir -p "$CHECKDIR"; } 2>&1 )
if [ $? -ne 0 ]; then
    printf "Directory does not exist, and couldn't be created : \n\t ${ERROR}\n"
    exit 1  
fi
ERROR=$( { ./useless.sh | sed s/Output/Useless/ > outfile; } 2>&1 )

ERROR=$( { echo "${writestr}" > ${writefile}; } 2>&1 )
if [ $? -ne 0 ]; then
    printf "Failed to write file '${writefile}': \n\t ${ERROR}\n"
    exit 1
fi