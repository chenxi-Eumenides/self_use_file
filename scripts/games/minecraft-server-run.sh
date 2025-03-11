#!/bin/bash

#java @user_jvm_args.txt -jar fabric-server-mc.1.18.2-loader.0.14.9-launcher.0.11.1.jar nogui "$@"

server='fabric-server-launch.jar'

if [ -z "$(echo $1 | sed -n "/^[0-9]\+$/p")" ] ; then
    min='1G'
else
    if [ $1 -le 128 ] ; then
        min=$1'G'
    else
        min=$1'M'
    fi
fi
if [ -z "$(echo $2 | sed -n "/^[0-9]\+$/p")" ] ; then
    max='4G'
else
    if [ $2 -le 128 ] ; then
        max=$2'G'
    else
        max=$2'M'
    fi
fi

java -Xms${min} -Xmx${max} -jar ${server} nogui
