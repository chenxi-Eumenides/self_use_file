#!/bin/bash

setup() {
    name="git_download"
    desc="get download url form github."
}

main() {
    # 获取参数
    [[ -z $1 ]] && echo "empty args" && return 1
    git=$1
    author=${git%/*}
    repo=${git#*/}
    [[ -z $2 ]] && version="latest" || version="tags/v$2"
    versions=$(curl -s https://api.github.com/repos/${author}/${repo}/releases/  | grep tag_name)
    echo $versions
    # 获取下载链接
    result=$(curl -s https://api.github.com/repos/${author}/${repo}/releases/${version}  | grep browser_download_url)
    i=0
    declare -A download_url
    for str in $result ; do
        [[ ${str##*\"} == ":" ]] && continue
        url=${str#*\"}
        url=${url%\"*}
        file=${url##*/}
        version=${url%/*}
        version=${version##*/}
        download_url["$i"]=$url
        echo "$i : $file ($url)"
        i=$(expr $i + 1)
    done
    read choose
    cd $work_url
    wget ${download_url["$choose"]}
}

init() {
    work_url=$(pwd)
    cd $(dirname $0)
    path=$(pwd)
    setup
    [[ -z "${name}" ]] && echo "empty name" && exit
}

help() {
    printf "desc: %s\n" ${desc}
    printf "args: $1 : author/repo { e.g. Genymobile/scrcpy }\n"
    printf "args: $2 : version { e.g. 3.0 or empty }\n"
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
