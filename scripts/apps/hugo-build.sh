#!/bin/bash

setup() {
    name="blog"
    desc="cheni-zqs的blog网站，用hugo搭建，主题为stack。"
}

main() {
    [[ -z $1 ]] && read -p "input commit info: " input && { [ -z $input ] && echo "no input." && return 1; }
    [[ -z $input ]] && input=$*
    update_git $input
    rm -r public/*
    rm -r public-github/
}

build_draft() {
    update_git $*
    rm -r ./public-github
    hugo --config hugo-github.yaml --buildDrafts
}

build() {
    update_git $*
    rm -r public
    hugo --config hugo-local.yaml
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
    cd public-github
    git push github
}

#delete

init() {
    cd $(dirname $0)
    path=$(pwd)
    setup
}

help() {
    echo "desc: ${desc}"
    echo "args: build | draft ."
    echo "commit: TYPE: content."
    echo "   e.t. update: this is a simple update info."
}

init
case $1 in
  "build")
    main ${@:2}
    ;;
  *)
    help
    ;;
esac
