#!/bin/bash

files="Apps Code Desktop Documents Downloads Games Music Pictures Public Scripts Templates Videos"
for file1 in `ls $HOME` ; do
    exist=false
    for file2 in $files ; do
        if [ "$file1" == "$file2" ] ; then
            exist=true
            break
        fi
    done
    if [ "$exist" == "false" ] ; then
        printf "%s " $file1
    fi
done
printf "\n"
