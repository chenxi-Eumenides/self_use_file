#!/bin/bash

setup() {
    name=""
    desc="just for test, dont run this file."
}

main() {

}

init() {
    cd $(dirname $0)
    path=$(pwd)
    setup
    [[ -z "${name}" ]] && echo "empty name" && exit
}

help() {
    echo "desc: ${desc}"
    echo "args: help ."
}

init
case $1 in
  "-h"|"--help"|"help")
    help
    ;;
  *)
    main $*
    ;;
esac
