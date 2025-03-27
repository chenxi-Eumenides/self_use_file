#!/bin/bash

config() {
    name="test" # 必填
    desc="just for test, dont run this file." # 描述

    # 0:verbose 1:info 2:warning 3:error 4:panic 5:quiet
    log_level=2 # 打印日志等级
    enable_log_file=false # 是否开启日志

    log_file="${file_name%.*}.log" # 日志文件名
    log_file_level=$log_level # 日志文件启用单独日志等级
    log_file_max_line=10000

}

hello() {
    log 1 "output hello"
    echo hello
}

main() {
    case $1 in
      "-h"|"--help"|"help")
        print_help
        ;;
      *)
        hello
        ;;
    esac
}

init() {
    cd $(dirname $0)
    file_name=$(basename $0)
    path=$(pwd)
    config && config_check || return 1
    log 0 "start user init"
    # 其他初始化操作


}

close() {
    log_flash
    exit 0
}

print_help() {
    echo "desc: ${desc}"
    echo "args: help ."
}

config_check() {
    return_code=0
    # 名称
    [[ -z "${name}" ]] && log 3 "empty name, disable to run" && return_code=1
    # 日志
    ! [[ $log_level =~ ^[0-5]$ ]] && log_level=2 && log 2 "log level wrong, set default. ($log_level)"
    $enable_log_file && ! [[ -f $log_file ]] && enable_log_file=false && log 2 "log file ${log_file} not exist, disable log file."
    $enable_log_file && ! [[ $log_file_level =~ ^[0-5]$ ]] && log_file_level=2 && log 2 "log file level wrong, set default. ($log_file_level)"
    $enable_log_file && ! [[ $log_file_max_line =~ ^[0-9]+$ ]] && log_file_max_line=2 && log 2 "log file max line wrong, set default. ($log_file_max line)"
    #


    return $return_code
}

log() {
    # 0:verbose 1:info 2:warning 3:error 4:panic 5:output
    level=$1 # 打印的日志等级
    msg=${@:2} # 日志内容
    func=${FUNCNAME[1]} # 调用log的函数
    log_level_name=("VERBOSE" "INFO" "WARN" "ERROR" "PANIC")

    # 检查传入的日志等级是否正确
    ! [[ $level =~ ^[0-5]$ ]] && level=3 && msg="args error ( \$1 : $1 )"
    # 如果上级是log_return，就再上层函数
    [[ $func == "log_return" ]] && func=${FUNCNAME[2]}

    # 构造日志内容
    content="[${log_level_name[${level}]}] (${func}) : ${msg}"

    if $enable_log_file ; then
        # 日志等级 >= 设定日志文件等级，写入日志
        if (( $level >= $log_file_level )) ; then
            echo "$content" >> $log_file 2>&1
        fi
    else
        # 日志等级 >= 设定的等级，输出日志
        if [[ $level = 5 ]] || (( $level >= $log_level )) ; then
            echo "$content"
        fi
    fi
}

log_command() {
    level=$1
    cmd=${@:2}
    func=${FUNCNAME[1]} # 调用log的函数
    log_level_name=("VERBOSE" "INFO" "WARN" "ERROR" "PANIC")

    # 检查传入的日志等级是否正确
    ! [[ $level =~ ^[0-5]$ ]] && level=3 && msg="args error ( \$1 : $1 )"
    # 如果上级是log_return，就再上层函数
    [[ $func == "log_return" ]] && func=${FUNCNAME[2]}

    # 构造日志内容
    content="[${log_level_name[${level}]}] (${func}) : ${msg}"

    if $enable_log_file ; then
        # 日志等级 >= 设定日志文件等级，写入日志
        if (( $level >= $log_file_level )) ; then
            echo "$content" >> $log_file 2>&1
        fi
    else
        # 日志等级 >= 设定的等级，输出日志
        if [[ $level = 5 ]] || (( $level >= $log_level )) ; then
            echo "$content"
        fi
    fi
}

log_return() {
    return_code=$1
    ! [[ $return_code =~ ^[0-9]+$ ]] && return_code=1
    log ${@:2}
    return $return_code
}

log_flash() {
    line=$(wc -l ${log_file} | awk '{print $1}')
    [ $line -gt $log_file_max_line ] && {
        log 2 "log file line ${line}, too large."
        [[ -f ${log_file}.temp ]] || touch ${log_file}.temp
        tail -n ${log_file_max_line:0:$[${#log_file_max_line}-1]} $log_file > ${log_file}.temp
        rm ${log_file}
        mv ${log_file}.temp $log_file
    }
    unset line
}

init && {
    main $*
}
close
