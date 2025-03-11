#!/bin/bash

declare -A dir_url
declare -A file_url
path=$(dirname $0)

var_name() {
    for line in $(awk 'NF && $0 !~ /^#/' $path/config/$(basename $0).conf) ; do
        file_url[${line%=*}]=$(eval echo ${line#*=})
    done
    all_file_key="${!file_url[*]}"
}

run_file() {
    cd "${target_file%%/*}"
    # 特殊值直接进行编辑
#    [[ "$name" == "self" ]] || [[ "$name" == "config" ]] && nano ${target_file} && return 0
    # 根据后缀运行脚本
    printf $(date +"[%y-%m-%d_%H:%M:%S]")
    if [ "${target_file#*.}" == "sh" ] ; then
        echo " sh" ${target_file} $*
        bash ${target_file} $*
    elif [ "${target_file#*.}" == "py" ] ; then
        echo " python" ${target_file} $*
        python ${target_file} $*
    else
        echo " " ${target_file} $*
        ${target_file}
    fi
}

find_file() {
    [[ -z "$1" ]] && return 1
    if [[ "./~" =~ "${1:0:1}" ]]; then
        target_file=$1
    else
        target_file=$(eval echo '$'"{file_url[\""${1}"\"]}")
    fi
    check_file "${target_file}" $2 && return 0
    p_help
    return 1
}

check_file() {
    # 是否传入了参数
    [[ ! -n "$1" ]] && ERROR_MSG="no arg, check input." && return 1
    # 是否是文件
    [[ ! -f "$1" ]] && ERROR_MSG="$1 not file, check input." && return 1
    # 特殊值跳过
#    [[ "$name" == "self" ]] || [[ "$name" == "config" ]] && return 0
    # 是否可执行
    [[ "$2" != "skip"  ]] && [[ ! -x "$1" ]] && ERROR_MSG="$1 cant run, please chmod +x"&& return 1
    return 0
}

p_list() {
    ERROR_MSG=" -l not finished."
    p_help
}

p_help() {
    if [[ -n "$ERROR_MSG" ]] ; then
        echo "$ERROR_MSG"
        echo "use -h to get USEAGE"
    elif [[ -n "$1" ]] ; then
        echo "$1"
        echo "use -h to get USEAGE"
    else
        echo " USEAGE:  run.sh [ options ] NAME [ args ]"
        echo ""
        echo " options:"
        echo "   -h | --help         :  print this useage."
        echo "   -w | --where        :  print file url."
        echo "   -e | --edit         :  edit file with ${EDITOR}."
        echo "   -r | --run          :  run file directly."
        echo " args:"
        echo "   NAME                :  ${all_file_key}"
        echo "   ARGS                :  script args. (e.t. start | stop | restart | help )"
    fi
    return 0
}

main() {
    [[ -z $1 ]] && p_help && exit 0
    case ${1} in
        "-h"|"--help")
            p_help ${@:2} && exit 0
        ;;
        "-l"|"--list")
            p_list $2 && exit 0
        ;;
        "-w"|"--where")
            name=$2
            find_file $2 skip || exit 1
            echo ${target_file} && exit 0
        ;;
        "-e"|"--edit")
            name=$2
            find_file $2 skip || exit 1
            $EDITOR ${target_file} && exit 0
        ;;
        "-r"|"--run")
            name=$2
            find_file $2 && run_file ${@:3} && exit 0
            check_file $2 && bash ${@:2} && exit 0
            p_help
            exit 1
        ;;
        *)
            p_help && exit 0
        ;;
    esac
}

var_name
main $*

exit 0
