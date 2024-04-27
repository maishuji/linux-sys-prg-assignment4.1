#!/bin/bash

filesdir=$1;
searchstr=$2;

if [ "$#" -ne 2 ]; then
    echo "Wrong number of args. Expected : 2, actual : $#"
    echo "Expected parameters : (1) file directory, (2) Search string"
    exit 1
fi

if [ ! -d "$filesdir" ]; then
  echo "The file directory '$filesdir' does not exist."
  exit 1
fi

count_lines=$(grep -R ${searchstr} ${filesdir} | wc -l )  
count_files=$(grep -R ${searchstr} ${filesdir} -c| grep -v ':0$'| wc -l )

echo "The number of files are ${count_files} and the number of matching lines are ${count_lines}"