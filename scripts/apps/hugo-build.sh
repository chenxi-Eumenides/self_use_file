#!/bin/bash

setup() {
    name="blog"
    desc="cheni-zqs的blog网站，用hugo搭建，主题为stack。"
}

git_commit() {
    [[ -z $1 ]] && read -p "input commit info: " input && {
        [ -z $input ] && echo "no input." && return 1
    }
    [[ -z $input ]] && input=$*
}

build_all() {
    build_local
    build_github
}

build_local() {
    [[ -d public ]] && rm -r public
    hugo --config hugo-local.yaml
}

build_github() {
    [[ -d docs ]] && rm -r docs
    hugo --config hugo-github.yaml --buildDrafts
    push_git
}

update_git() {
    git add ./
    if [[ -z $1 ]] ; then
        content="update: Auto build by runsh at $(date +%F_%T)"
    else
        content="$* at $(date +%F_%T)"
    fi
    git commit -m "${content}"
}

push_git() {
    git push github master:main
}

#delete

init() {
    cd $(dirname $0)
    path=$(pwd)
    setup
}

p_help() {
    echo "desc: ${desc}"
    echo "args: -l | --local COMMIT   : build local"
    echo "      -g | --github COMMIT  : build github"
    echo "      -a | --all COMMIT     : build both"
    echo "      -n | --no COMMIT      : git add . but not build"
    echo "      *                     : print help"
    echo "commit: TYPE: content"
    echo "   e.t. update: this is a simple update info."
}

init
case $1 in
    "-l"|"--local"|"local")
        git_commit ${@:2} || exit 1
        update_git $input
        build_local
        ;;
    "-g"|"--github"|"github")
        git_commit ${@:2} || exit 1
        update_git $input
        build_github
        ;;
    "-a"|"--all"|"all")
        git_commit ${@:2} || exit 1
        build_all
        ;;
    "-n"|"--no"|"no")
        git_commit ${@:2} || exit 1
        update_git $input
        ;;
    *)
        p_help && exit 0
        ;;
esac
