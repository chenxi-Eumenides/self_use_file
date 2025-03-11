#!/bin/bash

setup() {
    name="open-webui"
    desc="Web UI and OpenAI API for various LLM runners, including Ollama.\nUse uv."
}

start() {
    create_screen
    run_command_in_screen "uv run open-webui serve --port 11433"
}

stop() {
    run_command_in_screen '^C'
    sleep 0.1
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
    #SAVEIFS=$IFS
    #IFS=$'\n'
    #printf "desc: %s\n" ${desc}
    #IFS=$SAVEIFS
    echo -e "desc: ${desc}"
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
