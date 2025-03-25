#!/bin/bash

setup() {
    name="blog"
    desc="cheni-zqs的blog网站，用hugo搭建，主题为stack。"
    log="build.log"

    echo "" >> $log
    echo "[$(date +%F_%T)] auto build by build.sh" >> $log
}

get_commit() {
    [[ -z $1 ]] && read -p "input commit info: " input && {
        [[ -z "$input" ]] && echo "no input." && return 1
    }
    [[ -z "$input" ]] && input=$*
    return 0
}

build_local() {
    [[ -d public ]] && rm -r public
    echo "start build local"
    hugo --config hugo-local.yaml >> $log 2>&1
}

build_github() {
    [[ -d docs ]] && rm -r docs
    echo "start build github"
    hugo --config hugo-github.yaml --buildDrafts >> $log 2>&1
}

update_git() {
    echo "start git update"
    git add ./ >> $log 2>&1
    if [[ -z $1 ]] ; then
        content="update: Auto build by runsh at $(date +%F_%T)"
    else
        content="$* at $(date +%F_%T)"
    fi
    git commit -m "${content}" >> $log 2>&1
}

push_git() {
    echo "start git push to github"
    git push github master:main >> $log 2>&1
}

clear_log() {
    line=$(wc -l $log | awk '{print $1}')
    [ $line -gt 10000 ] && {
        echo "log too large, clear" >> $log 2>&1
        echo "clear log"
        [[ -f ${log}.temp ]] || touch ${log}.temp
        tail -n 1000 $log > ${log}.temp
        rm $log
        mv ${log}.temp $log
    } || echo "log line ${line}"
}

init() {
    cd $(dirname $0)
    path=$(pwd)
    setup
}

p_help() {
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
            p_help && return 0
            ;;
    esac
}

init
#TIMEFMT=$'\ntime\t%*E'
main $*
clear_log
