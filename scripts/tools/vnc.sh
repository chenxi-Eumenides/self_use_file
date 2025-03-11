#!/bin/bash

cd `dirname $0`
path=`pwd`

screen_name=vnc
service_name=vnc

create_screen() {
    if [ -z `screen -ls | grep -o "[0-9]*\.${1}  "` ] ; then
        screen -dmS $1
    fi
    printf "%s created.\n" $1
}

kill_screen() {
    screen -S $1 -X quit
    printf "%s closed.\n" $1
}

run_command() {
    screen -S $1 -X stuff "${@:2}"
    screen -S $1 -X stuff $'\n'
    printf "%s run '%s'.\n" $1 "${@:2}"
}

start() {
    create_screen ${screen_name}
    run_command ${screen_name} "vncserver :1"
}

stop() {
    run_command ${screen_name} '^C'
    sleep 0.5
    kill_screen ${screen_name}
}

restart() {
    stop
    start
}

help() {
    printf "args: start | stop | restart.\n"
}

case $1 in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "restart")
    restart
    ;;
  *)
    help
    ;;
esac
