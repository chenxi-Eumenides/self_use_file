#!/bin/bash


function scan_screen() {
    local index=0
    local name=""
    local uid=0
    local status=""
    number=0
    for line in `screen -wipe | tr -d "\t " | grep "[0-9]*\..*)"` ; do
        name=${line%%(*}
        namelist[${index}]=${name#*.}
        uid=${line%%.*}
        uidlist[${index}]=${uid}
        status=${line##*(}
        statuslist[${index}]=${status%)*}
        index=$[${index}+1]
        number=${index}
    done
    unset -v line
    return 0
}

function find_uid() {
    if [[ "$1" =~ ^[0-9]+$ ]] && [ $1 -lt ${number} ] ; then
        # is index
        echo ${uidlist[$1]}
        return 0
    fi
    local index=0
    while [ ${index} -lt ${number} ] ; do
        if [ ${uidlist[${index}]} = $1 ] ; then
            # is uid
            echo ${uidlist[${index}]}
            return 0
        elif [ ${namelist[${index}]} = $1 ] ; then
            # is name
            echo ${uidlist[${index}]}
            return 0
        fi
        index=$[${index}+1]
    done
    return -1
}

function print_list(){
    if [ -z $uidlist ] ; then
        return 1
    fi
    local index=0
    printf " index     -  uid      -  name\n"
    while [ ${index} -lt ${number} ] ; do
        printf " %s" ${index}
        if [ "${uidlist[${index}]}" = "${current_screen_uid}" ] ; then
            printf " (当前)"
        elif [ "${statuslist[${index}]}" = "Attached" ] ; then
            printf " (激活)"
        else
            printf " (后台)"
        fi
        printf "  -  %-8s" ${uidlist[${index}]}
        printf " -  %s" ${namelist[${index}]}
        printf "\n"
        index=$[${index}+1]
    done
    return 0
}

function return_screen() {
    echo "not finished."
    exit 0
    local input_uid=`find_uid $1`
    [ -z "${input_uid}" ] && return 1 # 没找到uid就退出
    [ "${input_uid}" == "${current_screen_uid}" ] && return 1 # 当前uid就是要去的uid就退出
    print_list
    echo "current_name:" ${current_screen_name} "\ncurrent_uid:" ${current_screen_uid} "\ntarget_uid:" ${input_uid} "\nssh_uid:" ${ssh_uid}
    if [ -z "${current_screen_uid}" ] ; then # 不在任何会话中
        echo "不在任何会话中"
        screen -r ${input_uid}
    elif [ "${current_screen_uid}" == "${ssh_uid}" ] ; then # 在ssh会话中
        echo "正在ssh会话中"
        screen -r ${input_uid}
    else # 在其他会话中
        if [ -n `screen -ls | grep "[0-9]*\.ssh" | grep -o "Attached"` ] ; then # 如果有ssh会话并且激活了
            echo "有ssh会话且激活了"
            screen -S ${current_screen_uid} -X detach
            screen -S ssh -X stuff "screen -r ${input_uid}"
            screen -S ssh -X stuff $'\n'
        elif [ -n `screen -ls | grep "[0-9]*\.ssh" | grep -o "Detached"` ] ; then # 如果有ssh会话并且没激活
            echo "有ssh会话但没激活"
            screen -S ${current_screen_uid} -X detach
            screen -r ${input_uid}
        else # 如果没有ssh会话
            echo "没有ssh会话"
            screen -S ${current_screen_uid} -X detach
            screen -r ${input_uid}
        fi
    fi
    return 0
}

function create_screen() {
    screen -dmS $1
    printf "%s created.\n" $1
    return 0
}

function kill_screen() {
    local index=0

    # kill all
    if [ $1 = "all" ] || [ $1 = "a" ] ; then
        index=0
        while [ ${index} -lt ${number} ] ; do
            if [ "${statuslist[${index}]}" != "Attached" ] ; then
                screen -S ${uidlist[${index}]} -X quit
                printf "kill %s - %s\n" ${uidlist[${index}]} ${namelist[${index}]}
            fi
            index=$[${index}+1]
        done
        return 0
    fi

    # kill single
    local input=`find_uid $1`
    [ -z "${input}" ] && return 1
    screen -S ${input} -X quit
    printf "kill %s\n" ${input}
    return 0
}

function help(){
    printf "usage: -r [name/id] :  return\n"
    printf "       -n [name/id] :  new\n"
    printf "       -k [name/id] :  kill\n"
    printf "       -p           :  print\n"
    return 0
}

scan_screen
current_screen_uid=${STY%%.*}
current_screen_name=${STY#*.}
ssh_uid=`screen -ls | grep "[0-9]*\.ssh" | grep -o "[1-9][0-9]*"`
while getopts ':r:n:k:x:p' ARGS ; do
case $ARGS in
  r)
    return_screen $OPTARG
    ;;
  n)
    create_screen $OPTARG
    ;;
  k)
    kill_screen $OPTARG
    ;;
  x)
    echo "-x $OPTARG"
    ;;
  p)
    print_list
    ;;
  ?)
    help
    ;;
  :)
    help
    ;;
  *)
    echo " - 处理选项时出现未知错误"
    exit 1
    ;;
esac
done
