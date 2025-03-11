#!/bin/bash

setup() {
    name="update_git_script"
    desc="Update git repo: self_use_scripts."
    DEBUG=false

    scr=$HOME/Code/Scripts
    tem=$HOME/Templates
    con=$HOME/Documents/Files/Linux/config
    tgt=$(pwd)
}

main() {
    [[ -z $1 ]] && read -p "input commit info: " input && { [ -z $input ] && echo "no input." && return 1; }
    copy_file
    delete_file
    [[ -z $input ]] && input=$*
    git_update $input
}

copy_file() {
    try_cp $scr/run.sh $tgt/scripts/main.sh

    try_cp $scr/config/run.sh.conf $tgt/scripts/config/main.sh.conf

    try_cp $scr/tools/auto_attach_tmux.sh $tgt/scripts/tools/auto_attach_tmux.sh
    try_cp $scr/tools/check_home_dir.sh $tgt/scripts/tools/check_home_dir.sh
    try_cp $scr/tools/ddns.sh $tgt/scripts/tools/ddns.sh
    try_cp $scr/tools/get_ip.sh $tgt/scripts/tools/get_ip.sh
    try_cp $scr/tools/git_download.sh $tgt/scripts/tools/git_download.sh
    try_cp $scr/tools/screen.sh $tgt/scripts/tools/screen.sh
    try_cp $scr/tools/v2ray_dat_update.sh $tgt/scripts/tools/v2ray_dat_update.sh
    try_cp $scr/tools/vnc.sh $tgt/scripts/tools/vnc.sh

    try_cp $tem/Empty_Bash.sh $tgt/templates/Empty_Bash.sh
    try_cp $tem/Empty_Script_in_Screen.sh $tgt/templates/Empty_Script_in_Screen.sh
    try_cp $tem/Empty_Script.sh $tgt/templates/Empty_Script.sh
    try_cp $tem/Empty_Service.service $tgt/templates/Empty_Service.service

    try_cp $con $tgt/config

    try_cp $HOME/Apps/blog/build.sh $tgt/scripts/apps/hugo-build.sh
    try_cp $HOME/Apps/AI-webUI/run.sh $tgt/scripts/apps/openwebui-run.sh

    try_cp $HOME/Games/Minecraft/Server/run.sh $tgt/scripts/games/minecraft-server-manager-run.sh
    try_cp $HOME/Games/Minecraft/Server/default.run_server.sh $tgt/scripts/games/minecraft-server-run.sh
    try_cp $HOME/Games/Terraria/run.sh $tgt/scripts/games/terraria-server-run.sh
    try_cp $HOME/Games/Tmodloader/run.sh $tgt/scripts/games/tmodloader-server-manager-run.sh
}

delete_file() {
    for line in $(cat .gitignore); do
        [[ $line == ".git" ]] && continue
        delete_find $line
    done
}

delete_find() {
#    echo $1 && return 0
    fd --hidden --no-ignore $1 --exec rm {}
}

try_cp() {
    [[ -n $1 ]] || return 1
    [[ -n $2 ]] || return 1
    $DEBUG && echo "cp $1 $2" && return 0

    s=$1
    t=$2
    [[ -f $s ]] && {
        # $s is file
        [[ -d $t ]] && t=$t/$(basename $s)
        [[ -f $t ]] && {
            # $t is file
            md5_s=$(md5sum $s | awk '{print $1}')
            md5_t=$(md5sum $t | awk '{print $1}')
            [[ $md5_s != $md5_t ]] && {
                cp $s $t
                echo copy $s
            } || echo same $s
            return 0
        } || echo $t is not existed
    }
    [[ -d $s ]] && {
        [[ -e $t ]] || { mkdir $t; echo mkdir $t;}
        [[ -d $t ]] && {
            md5_s=$(cd $s; fd . -t f --exec md5sum {} | sort | md5sum)
            md5_t=$(cd $t; fd . -t f --exec md5sum {} | sort | md5sum)
            [[ $md5_s != $md5_t ]] && {
                cp -r $s/* $t
                echo copydir $s $t
            } || echo samedir $s
            return 0
        } || echo $t is not existed
    }
    return 1
}

git_update() {
    $DEBUG && echo "git update" && return 0
    git add ./
    if [[ -z $1 ]] ; then
        content="update: auto build by scripts at $(date +%F_%T)"
    else
        content="$* at $(date +%F_%T)"
    fi
    git commit -m "${content}"
    git push github
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
    exit
    ;;
  *)
    main $*
    ;;
esac
