#!/bin/bash

cd `dirname $0`
path=`pwd`

# choose which server

default_server=1

# search run.sh add path to serverlist
index=0
for server in $(ls -d server-*/) ; do
    if [ -n `ls ${server} | grep run_server.sh` ] ; then
        serverlist[${index}]=${server::`expr ${#server} - 1`}
        index=`expr ${index} + 1`
    fi
done
unset server

# print options
index=0
while [ ${index} -lt ${#serverlist[@]} ] ; do
    printf "%d : %s\n" ${index} ${serverlist[${index}]}
    index=`expr ${index} + 1`
done

# input option
printf "input index\n : "
read choose_index
if [ "${choose_index}" == "" ] ; then
    choose_index=${default_server}
elif ! [[ "${choose_index}" =~ ^[0-9]+$ ]] ; then
    printf "not number\n"
    exit
elif ! [ ${choose_index} -lt ${#serverlist[@]} ] ; then
    printf "too large\n"
    exit
fi

# get servername
server=${serverlist[${choose_index}]}
unset choose_index
unset serverlist

# end config and start
printf "input enter to start ${server}"
read

# switch screen to run server

# if no screen , create it
if [ -z `screen -ls | grep -o "[0-9]*\.${server}  "` ] ; then
    screen -dmS ${server}
fi
printf "%s is running\n" ${server}

# start server
shell[0]=$"cd ${path}/${server}/"
shell[1]=$"./run.sh"
shell[2]=$"n"
shell[3]=$"1"
shell[4]=$"1"
shell[5]=$"1"

index=0
while [ ${index} -lt ${#shell[@]} ] ; do
    echo command: ${shell[${index}]}
    screen -S ${server} -X stuff "${shell[${index}]}"
    screen -S ${server} -X stuff $'\n'
    index=`expr ${index} + 1`
done
printf "start running %s\n" ${server}

