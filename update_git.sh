#!/bin/bash

setup() {
    name="update_git_script"
    desc="Update git repo: self_use_scripts."
    DEBUG=false

    delete_list=(".zsh")

    scr=$HOME/Code/Scripts
    tem=$HOME/Templates
    con=$HOME/Documents/Files/Linux/config
    tgt=$(pwd)
}

copy_file() {
    copy_script
    copy_config
    copy_template
}

copy_script() {
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

    try_cp $HOME/Apps/blog/build.sh $tgt/scripts/apps/hugo-build.sh
    try_cp $HOME/Apps/AI-webUI/run.sh $tgt/scripts/apps/openwebui-run.sh

    try_cp $HOME/Games/Minecraft/Server/run.sh $tgt/scripts/games/minecraft-server-manager-run.sh
    try_cp $HOME/Games/Minecraft/Server/default.run_server.sh $tgt/scripts/games/minecraft-server-run.sh
    try_cp $HOME/Games/Terraria/run.sh $tgt/scripts/games/terraria-server-run.sh
    try_cp $HOME/Games/Tmodloader/run.sh $tgt/scripts/games/tmodloader-server-manager-run.sh
}

copy_config() {
    try_cp $con $tgt/config
    #try_cp /
}

copy_template() {
    try_cp $tem/Empty_Bash.sh $tgt/templates/Empty_Bash.sh
    try_cp $tem/Empty_Script_in_Screen.sh $tgt/templates/Empty_Script_in_Screen.sh
    try_cp $tem/Empty_Script.sh $tgt/templates/Empty_Script.sh
    try_cp $tem/Empty_Service.service $tgt/templates/Empty_Service.service
    try_cp $tem/Empty_Timer.timer $tgt/templates/Empty_Timer.timer

    try_cp $tem/Empty_Desktop_File.desktop $tgt/templates/Empty_Desktop_File.desktop
    try_cp $tem/Empty_Doc.docx $tgt/templates/Empty_Doc.docx
    try_cp $tem/Empty_Excel.docx $tgt/templates/Empty_Excel.docx
    try_cp $tem/Empty_File $tgt/templates/Empty_File
    try_cp $tem/Empty_PPT.pptx $tgt/templates/Empty_PPT.pptx
}

delete_file() {
    for item in ${delete_list}; do
        delete_find $item
    done
}

delete_find() {
#    echo $1 && return 0
    fd --hidden --no-ignore $1 --exec rm {}
}

try_cp() {
    [[ -n $1 ]] || return 1
    [[ -n $2 ]] || return 1

    s=$1
    t=$2
    if [[ -f $s ]] ; then
        # $s is file
        [[ -d $t ]] && t=$t/$(basename $s)
        if [[ -f $t ]] ; then
            # $t is file
            if [[ $(get_md5 $s) != $(get_md5 $t) ]] ; then
                cp $s $t
                echo copy $s
                if [[ "$s" == "$tem/Empty_File" ]] ; then
                    echo $(get_md5 $s)
                    echo $(get_md5 $t)
                fi
            else
                $DEBUG && echo skip $s
            fi
            return 0
        fi
        [[ -e $(dirname $t) ]] || {
            mkdir -p $(dirname $t)
            echo "$(dirname $t) not existed, create folder"
        }
        cp $s $t
        echo copy $t
        return 0
#        echo $t is not existed
    elif [[ -d $s ]] ; then
        [[ -e $t ]] || { mkdir $t; echo mkdir $t;}
        [[ -d $t ]] && {
#            md5_s=$(cd $s; fd . -t f --exec md5sum {} | sort | md5sum)
#            md5_t=$(cd $t; fd . -t f --exec md5sum {} | sort | md5sum)
            if [[ $(get_md5 $s) != $(get_md5 $t) ]] ; then
                cp -r $s/* $t
                echo copydir $s $t
            else
                $DEBUG && echo "skip dir $s"
            fi
            return 0
        } || echo "$t is not existed"
    fi
    return 1
}

get_md5() {
    if [[ -f $1 ]] ; then
        echo $(md5sum $1 | awk '{print $1}')
    elif [[ -d $1 ]] ; then
        echo $(cd $1; fd . -t f --exec md5sum {} | sort | md5sum)
    fi
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

main() {
    init
    case ${1-ERROR_NOTSET} in
      "-h"|"--help"|"help")
        help
        return 0
        ;;
      "ERROR_NOTSET")
        read -p "input commit info: " input
        [[ -z $input ]] && echo "no input." && return 1
        copy_file
        delete_file
        git_update $input
        ;;
      *)
#        [[ -z $1 ]] && read -p "input commit info: " input && { [ -z $input ] && echo "no input." && return 1; }
        copy_file
        delete_file
        [[ -z $input ]] && input=$*
        git_update $input
        ;;
    esac
}

main $*
