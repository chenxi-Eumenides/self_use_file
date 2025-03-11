#!/bin/bash

setup() {
    name=""
    desc="just for test, dont run this file."
}

start() {
    create_screen
    run_command_in_screen ""
}

stop() {
    run_command_in_screen '^C'
    sleep 0.05
    kill_screen
}

restart() {
    stop
    start
}

run_command() {
    exec $*
}

run_command_in_screen() {
    screen -S ${name} -X stuff "${@}\n"
    printf "%s run '%s'.\n" ${name} "${@}"
}

create_screen() {
    if [ -z $(screen -ls | grep -o "[0-9]*\.${name}") ] ; then
        screen -dmS ${name}
        printf "%s created.\n" ${name}
    else
        printf "%s exist.\n" ${name}
    fi
}

kill_screen() {
    screen -S ${name} -X quit
    printf "%s closed.\n" ${name}
}

init() {
    cd $(dirname $0)
    path=$(pwd)
    setup
    [[ -z "${name}" ]] && echo "empty name" && exit
}

back_shell() {
    if [ -n $(screen -ls | grep -o "[0-9]*\.${name}") ] ; then
        exec screen -R ${name}
    else
        echo "no screen name: ${name}"
    fi
}

help() {
    printf "desc: %s\n" ${desc}
    printf "args: start | stop | restart | shell .\n"
}

init
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
  "shell")
    back_shell
    ;;
  *)
    help
    ;;
esac
