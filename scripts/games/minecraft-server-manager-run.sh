#!/bin/bash

cd `dirname $0`
path=`pwd`

# choose which server

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
if ! [[ "${choose_index}" =~ ^[0-9]+$ ]] ; then
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

# get args
echo '0 : no args'
echo '1 : 256M-256M       2 : 512M-1G'
echo '3 : 2G-5G           4 : 4G-8G'
printf 'input index or enter to input Xms and Xmx :'
read choose
case ${choose} in
  0) args="" ;;
  1) args=" 256 256" ;;
  2) args=" 512 1" ;;
  3) args=" 2 5" ;;
  4) args=" 4 8" ;;
  *)
    printf "Xms : "
    read s
    if [ -z $s ] ; then
        s=2
    fi
    printf "Xmx : "
    read m
    if [ -z $m ] ; then
        m=5
    fi
    args=" ${s} ${m}"
    ;;
esac

# end config and start
printf "\ninput enter to start server"
read

# switch screen to run server

# if no screen , create it
if [ -z `screen -ls | grep -o "[0-9]*\.${server}  "` ] ; then
    screen -dmS ${server}
fi
printf "%s is running\n" ${server}

# start server
shell[0]=$"cd ${path}/${server}/"
shell[1]=$"./run_server.sh${args}"

index=0
while [ ${index} -lt ${#shell[@]} ] ; do
    echo command: ${shell[${index}]}
    screen -S ${server} -X stuff "${shell[${index}]}"
    screen -S ${server} -X stuff $'\n'
    index=`expr ${index} + 1`
done
printf "start running %s\n" ${server}

