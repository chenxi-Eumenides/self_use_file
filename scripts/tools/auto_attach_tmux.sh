#!/bin/bash

setup() {
    name="tmux_auto_attach"
    desc="attach tmux default"

    tmux_name="default"
    split_width=100
    DEBUG=false

    # 在screen内，直接退出
    [[ -n $STY ]] && { [[ -z $1 ]] && echo "ERROR: inside screen: $STY";    exit; }

    # 在tmux内，直接退出
    current_tmux=$(echo ${TMUX} | sed "s/^\/.*\///" | sed "s/,.*$//")
    [[ -n $TMUX ]] && { [[ -z $1 ]] && echo "ERROR: inside tmux: ${current_tmux}"; exit; }

    # 默认tmux存在检测
    ! [[ $(tmux has -t ${tmux_name} 2>&1 | wc -c) -eq 0 ]] && tmux new -d -s ${tmux_name}
    $DEBUG && echo "INIT: tmux running"

    # 获取屏幕宽度
    width=$(tput cols)
    $DEBUG && echo "INIT: terminal width: ${width}"

    # 获取会话窗口数、面板数
    win_num=$(tmux list-windows -t ${tmux_name} | wc -l)
    pane_num=$(tmux list-panes -t ${tmux_name}:0 | wc -l)
    $DEBUG && echo "INIT: ${tmux_name} has ${win_num} windows, ${pane_num} panes"
}

main() {
    if [[ $width -ge $split_width ]] ; then
        # 宽度大于等于设定值
        $DEBUG && echo "MAIN: width:${width} >= split_width:${split_width}"
        if [[ $pane_num -eq 1 ]] ; then
            # 有1个面板
            $DEBUG && echo "MAIN: 1 pane, split to 2 pane"
            tmux split-window -h -t ${tmux_name}:0
            if [[ $win_num -gt 1 ]] ; then
                # 如果有第二个窗口，交换后销毁。
                $DEBUG && echo "MAIN: 2 windows, swap pane from ${tmux_name}:1.0 to ${tmux_name}:0.1 "
                tmux swap-pane -s ${tmux_name}:0.1 -t ${tmux_name}:1.0
                tmux kill-window -t ${tmux_name}:1
            fi
        else
            # 有2个面板
            $DEBUG && echo "MAIN: has 2 pane, skip"
        fi
    else
        # 宽度小于100
        $DEBUG && echo "MAIN: width:${width} < split_width:${split_width}"
        if [[ $pane_num -eq 2 ]] ; then
            # 有2个面板
            if [[ $win_num -eq 1 ]] ; then
                $DEBUG && echo "MAIN: 1 window 2 pane, move pane2 to new"
                tmux new-window -t ${tmux_name}
                tmux join-pane -s ${tmux_name}:0.1 -t ${tmux_name}:1.0
                tmux kill-window -t ${tmux_name}:1
            else
                    $DEBUG && echo "MAIN: 2 window 2 pane, move pane2 to old"
                tmux join-pane -s ${tmux_name}:0.1 -t ${tmux_name}:1.1
            fi
        else
            # 有1个面板
            $DEBUG && echo "MAIN: has 1 pane, skip"
        fi
    fi
    $DEBUG && echo "MAIN: attach tmux: ${tmux_name}:0"
    $DEBUG && echo "MAIN: tmux status: $(tmux list-windows -t ${tmux_name} | sed 's/ \[lay.*)//')"
    tmux select-pane -t ${tmux_name}:0.0
    tmux attach -t ${tmux_name}
}

init() {
#    cd $(dirname $0)
    path=$(pwd)
    setup
    [[ -z "${name}" ]] && echo "empty name" && exit
}




help() {
    printf "desc: %s\n" ${desc}
    printf "args: help .\n"
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
