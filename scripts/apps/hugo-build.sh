#!/bin/bash

config() {
    name="blog" # 必填
    desc="我自己的blog网站，用hugo搭建，主题为stack。\n构建两个版本：本地、github.io" # 描述

    # 0:verbose 1:info 2:warning 3:error 4:panic 5:quiet
    log_level=1 # 输出日志等级
    enable_log_file=true # 是否开启日志

    log_file="${file_name%.*}.log" # 日志文件名
    log_file_max_line=10000

    hugo_arg_local="--config hugo-local.yaml"
    hugo_arg_github="--config hugo-github.yaml --buildDrafts"
    arg_quiet="--quiet"
}

get_commit() {
    log 1 "start get commit"
    [[ -z $1 ]] && read -p "input commit info: " input && {
        [[ -z "$input" ]] && log 3 "input empty, exit" && return 1
    }
    [[ -z "$input" ]] && input=$*
}

build_local() {
    local hugo_log_level=1
    log 1 "start build local"
    [[ -d public ]] && rm -r public
    if $enable_log_file ; then
        hugo ${hugo_arg_local} $( (( $hugo_log_level >= $log_level )) || echo $arg_quiet) >> $log_file 2>&1
    else
        hugo ${hugo_arg_local} $( (( $hugo_log_level >= $log_level )) || echo $arg_quiet)
    fi
}

build_github() {
    log 1 "start build github"
    local hugo_log_level=1
    [[ -d docs ]] && rm -r docs
    if $enable_log_file ; then
        hugo ${hugo_arg_github} $( (( $hugo_log_level >= $log_level )) || echo $arg_quiet)  >> $log_file 2>&1
    else
        hugo ${hugo_arg_github} $( (( $hugo_log_level >= $log_level )) || echo $arg_quiet)
    fi
}

update_git() {
    log 1 "start git update"
    local git_log_level=1
    if [[ -z $1 ]] ; then
        content="update: Auto build by runsh at $(date +%F_%T)"
    else
        content="$* at $(date +%F_%T)"
    fi
    if $enable_log_file ; then
        git add ./ >> $( (( $git_log_level >= $log_level )) && echo "$log_file" || echo "/dev/null" ) 2>&1
        git commit -m "${content}" $( (( $git_log_level >= $log_level )) || echo \-$arg-quiet ) >> $log_file 2>&1
    else
        git add ./
        git commit -m "${content}" $( (( $git_log_level >= $log_level )) || echo \-$arg-quiet )
    fi
}

push_git() {
    log 1 "start git push to github"
    local git_log_level=1
    if $enable_log_file ; then
        git push github master:main $( (( $git_log_level >= $log_level )) || echo \-$arg-quiet ) >> $log_file 2>&1
    else
        git push github master:main $( (( $git_log_level >= $log_level )) || echo \-$arg-quiet )
    fi
}

main() {
    case $1 in
        "-l"|"--local"|"local")
            build_local || return 1
            get_commit ${@:2} || return 1
            update_git $input || return 1
            ;;
        "-g"|"--github"|"github")
            build_github || return 1
            get_commit ${@:2} || return 1
            update_git $input || return 1
            push_git || return 1
            ;;
        "-a"|"--all"|"all")
            build_local || return 1
            build_github || return 1
            get_commit ${@:2} || return 1
            update_git $input || return 1
            push_git || return 1
            ;;
        "-n"|"--no"|"no")
            case $2 in
                "l"|"local")
                    build_local || return 1
                    ;;
                "g"|"github")
                    build_github || return 1
                    ;;
                *)
                    build_local || return 1
                    build_github || return 1
                    ;;
            esac
            return 0
            ;;
        *)
            print_help && return 0
            ;;
    esac
}

init() {
    cd $(dirname $0)
    file_name=$(basename $0)
    path=$(pwd)
    config && config_check || return 1
    log 1 "start init"
    # 其他初始化操作


}

close() {
    log 1 "finished"
    log_flash
    exit 0
}

print_help() {
    echo "desc: ${desc}"
    echo "args: -l | --local COMMIT    : build local"
    echo "      -g | --github COMMIT   : build github"
    echo "      -a | --all COMMIT      : build both"
    echo "      -n | --no local/github : build but not git"
    echo "      *                      : print help"
    echo "commit:  TYPE: content"
    echo "   e.t.  init: init git info."
    echo "          new: add new file or new feature info."
    echo "          fix: fix bug or fix wrong thing info."
    echo "         feat: new feature or new method info."
    echo "        merge: merge code or file info."
    echo "       update: update something info."
    echo "     *   test: add test info."
    echo "     *   perf: improve performance or experience info."
    echo "     *   docs: add test info."
    echo "     *   sync: sync main or master branch info."
}

config_check() {
    return_code=0
    # 名称
    [[ -z "${name}" ]] && log 3 "empty name, disable to run" && return_code=1
    # 日志
    ! [[ $log_level =~ ^[0-5]$ ]] && log_level=2 && log 2 "log level wrong, set default. ($log_level)"
    $enable_log_file && ! [[ -f $log_file ]] && enable_log_file=false && log 2 "log file ${log_file} not exist, disable log file."
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
    log_color=("\e[37m" "\e[97m" "\e[33m" "\e[31m" "\e[91m")

    # 检查传入的日志等级是否正确
    ! [[ $level =~ ^[0-5]$ ]] && level=3 && msg="args error ( \$1 : $1 )"
    # 如果上级是log_return，就再上层函数
    [[ $func == "log_return" ]] && func=${FUNCNAME[2]}

    # 构造并输出
    if $enable_log_file ; then
        content="[${log_level_name[${level}]}] (${func}) : ${msg}"
        # 日志等级 >= 设定的日志等级，写入日志
        if (( $level >= $log_level )) ; then
            echo "$content" >> $log_file 2>&1
        fi
    else
        content="[${log_color[${level}]}${log_level_name[${level}]}\e[0m] (${func}) : ${msg}"
        # 日志等级 >= 设定的日志等级，输出日志
        if [[ $level = 5 ]] || (( $level >= $log_level )) ; then
            echo -e "$content"
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
    $enable_log_file || return 0
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
