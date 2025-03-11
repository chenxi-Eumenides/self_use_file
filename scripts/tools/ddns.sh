#!/usr/bin/env bash

# Author: tyasky

configfile="$(cd $(dirname $0);pwd)/../config/ddns.ini"

# 第二个参数指定额外不编码的字符
# 笔记：[-_.~a-zA-Z0-9$2] 中的-字符用于表示区间，放到中间会出意外结果
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o
    for pos in $(awk "BEGIN { for ( i=0; i<$strlen; i++ ) { print i; } }")
    do
        c=${string:$pos:1}
        case $c in
            [-_.~a-zA-Z0-9$2] ) o="${c}" ;;
            * ) o=`printf '%%%02X' "'$c"`
        esac
        encoded="$encoded$o"
    done
    echo "${encoded}"
}

send_request() {
    timestamp=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
    # 服务器拒绝重放攻击（本次与前一次请求数据相同返回错误)，SignatureNonce 需赋值随机数而不能是时间戳(可能同一秒两次请求)
    nonce=`openssl rand -base64 8 | md5sum | cut -c1-8`
    args="AccessKeyId=$ak&Format=json&SignatureMethod=HMAC-SHA1&SignatureNonce=$nonce&SignatureVersion=1.0&Timestamp=$timestamp&Version=2015-01-09&$1"
    # 签名要求参数按大小写敏感排序(sort 在本地语言环境可能会忽略大小写排序)：LC_ALL=c sort
    args=`echo "$args" | sed 's/\&/\n/g' | LC_ALL=c sort | xargs | sed 's/ /\&/g'`
    CanonicalizedQueryString=$(urlencode "$args" "=&")
    StringToSign="GET&%2F&$(urlencode $CanonicalizedQueryString)"
    Signature=$(urlencode $(echo -n "$StringToSign" | openssl dgst -sha1 -hmac "$sk&" -binary | openssl base64))
    echo $(curl -k -s "https://alidns.aliyuncs.com/?$args&Signature=$Signature")
}

getValueFromJson() {
    local json="$1"
    local key="^$2："
    echo $json | sed 's/":/：/g;s/"//g;s/,/\n/g' | grep -E $key | awk -F： '{ print $2 }'
}

DescribeSubDomainRecords() {
    local host="$1"
    local type="$2"
    send_request "Action=DescribeSubDomainRecords&SubDomain=$host.$domain&Type=$type"
}

UpdateDomainRecord() {
    local host="$1"
    local type="$2"
    local value="$3"
    local recordid=$(getValueFromJson `DescribeSubDomainRecords "$host" "$type"` "RecordId")
    send_request "Action=UpdateDomainRecord&RR=$host&RecordId=$recordid&Type=$type&Value=$value"
}

AddDomainRecord() {
    local host="$1"
    local type="$2"
    local value="$3"
    send_request "Action=AddDomainRecord&DomainName=$domain&RR=$host&Type=$type&Value=$value"
}

DeleteSubDomainRecords() {
    local host="$1"
    send_request "Action=DeleteSubDomainRecords&DomainName=$domain&RR=$host"
}

resolveDomain() {
    local host="$1"
    local type="$2"
    local downvalue="$3"
    rslt=`DescribeSubDomainRecords "$host" "$type"| grep TotalCount`
    if [ -z "$rslt" ];then
        echo "未获取到阿里云查询结果"
        return 1
    fi
    upvalue=$(getValueFromJson "$rslt" "Value")
    printf "$host.$domain ( $upvalue -> "

    if [ -z "$downvalue" ]; then
        echo "空"
        return 1
    fi
    printf "$downvalue"

    if [ "$upvalue" = "$downvalue" ]; then
        echo " 无需更新 )"
    elif [ -n "$upvalue" ]; then
        echo " 更新解析记录 )"
        UpdateDomainRecord "$host" "$type" "$downvalue"
        changed_flag=true
    else
        echo " 添加解析记录 )"
        AddDomainRecord "$host" "$type" "$downvalue"
        changed_flag=true
    fi
}

updateDomain() {
    # 获取默认的ip
    local ip_type=$1
    [[ $ip_type == "v4" ]] && DNS_type="A"
    [[ $ip_type == "v6" ]] && DNS_type="AAAA"
    local method_list=$(parse_ini "$configfile" list $ip_type)
    # cmd_list=${cmd_list//\\/\\\\}
    local ip=""
    # default_ip_list=()
    for method in ${method_list}; do
        cmd=$(parse_ini "$configfile" list $method)
        $(isCmdExist $cmd) && ip=$(eval $cmd) || continue
        [[ $ip_type == "v6" ]] && break
        $(is_valid_ip $ip_type $ip) && break || ip=""
    done
    [[ -z $ip ]] && echo $ip_type empty && return 1
    [[ $ip_type == "v4" ]] && ipv4=$ip
    [[ $ip_type == "v6" ]] && ipv6=$ip

    value_list=$(parse_ini "$configfile" "IP${ip_type}")
    echo "${value_list[@]}" | while read i && [ -n "$i" ]; do
        subdomain=${i%=*}
        method=${i#*=}
        if [[ $method == "default" ]]; then
            resolveDomain "$subdomain" "$DNS_type" "$ip"
        else
            cmd=$(parse_ini "$configfile" list "$method")
            $(isCmdExist $cmd) && ip=$(eval $cmd) || continue
            $(is_valid_ip $ip_type $ip) && resolveDomain "$subdomain" "$DNS_type" "$ip" || continue
        fi
    done
}

test1() {
    methods=$(parse_ini $configfile list v4)
    for method in ${methods}; do
        echo $(parse_ini "$configfile" list $method)
    done
    return
    value_list=$(parse_ini $configfile IPv4)
    value_list=${value_list//\\/\\\\}
    # echo ${value_list[@]}
    for value in ${value_list[@]}; do
        subdomain=${value%=*}
        cmdline=${value#*=}
        echo $subdomain $cmdline
        rslt=$(DescribeSubDomainRecords "$subdomain" "A" | grep TotalCount)
        upvalue=$(getValueFromJson "$rslt" "Value")
        printf "$subdomain.$domain ( $upvalue -> "
        break
    done
}

init() {
    ak=`parse_ini "$configfile" common AccessKeyID`
    sk=`parse_ini "$configfile" common AccessKeySecret`
    domain=`parse_ini "$configfile" common DomainName`

    TIMEOUT=2
}

main() {
    changed_flag=false

    updateDomain v4
    echo ""
    updateDomain v6

    if $changed_flag ; then
        echo "sending email"
        send_email $ipv4 $ipv6
        update_ssh_motd $ipv4 $ipv6
    fi
}

isCmdExist() {
    if type $1 >/dev/null 2>&1;then
        echo true
    else
        echo false
    fi
}

is_valid_ip() {
    local t_ip=$1
    local ip=$2
    if [[ $t_ip == "v4" ]]; then
        # 正则表达式匹配IPv4地址
        local regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9]{1,2})$'

        [[ $ip =~ $regex ]] && echo true || echo false
    elif [[ $t_ip == "v6" ]]; then
        # 正则表达式匹配IPv6地址
        local regex='^(?:(?:[A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,7}:|(?:[A-Fa-f0-9]{1,4}:){1,6}:[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,5}(:[A-Fa-f0-9]{1,4}){1,2}|(?:[A-Fa-f0-9]{1,4}:){1,4}(:[A-Fa-f0-9]{1,4}){1,3}|(?:[A-Fa-f0-9]{1,4}:){1,3}(:[A-Fa-f0-9]{1,4}){1,4}|(?:[A-Fa-f0-9]{1,4}:){1,2}(:[A-Fa-f0-9]{1,4}){1,5}|[A-Fa-f0-9]{1,4}:((:[A-Fa-f0-9]{1,4}){1,6})|:((:[A-Fa-f0-9]{1,4}){1,7}|:)|fe80:(:[A-Fa-f0-9]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$'
        # 上面的正则不能正确匹配，所以不判断，直接当真
        echo true && return

        [[ $ip =~ $regex ]] && echo true || echo false
    else
        echo false
    fi
}

parse_ini() {
  cat "$1" | gawk -v section="$2" -v key="$3" '
    BEGIN {
      if (length(key) > 0) { params=3 }
      else if (length(section) > 0) { params=2 }
      else { params=1 }
    }
    match($0,/#/) { next }
    match($0,/^\[(.+)\]$/){
      current=substr($0, RSTART+1, RLENGTH-2)
      found=current==section
      if (params==1) { print current }
    }
    match($0,/(.+)=(.+)/,a) {
       if (found) {
         if (params==3 && key==a[1]) { print a[2] }
         if (params==2) { printf "%s=%s\n",a[1],a[2] }
       }
    }'
}

getip() {
    for f in `parse_ini "$configfile" list v4`; do
        command=`parse_ini "$configfile" list "$f"`
        echo "$f : $command ->" $(timeout $TIMEOUT $command || echo "timeout")
    done
    echo ""
    for f in `parse_ini "$configfile" list v6`; do
        command=`parse_ini "$configfile" list "$f"`
        echo "$f : $command ->" $(timeout $TIMEOUT $command || echo "timeout")
    done
}

send_email() {
    echo "ipv4:$1\nipv6:$2" | mailx -s "更新了服务器ip" "1742041477@qq.com"
}

update_ssh_motd() {
    sed -i s/^ipv4:.*/ipv4:${$1}/g /etc/ssh/ssh_banner
    sed -i s/^ipv6:.*/ipv6:${$2}/g /etc/ssh/ssh_banner
}

usage() {
    echo "Usage:"
    echo "-f file1  Read config from file1" 
    echo "-d test   DeleteSubDomainRecords of test.xx.com"
    echo "-h        Show usage"
    exit
}

# init;test1;exit
# init;getip;exit

set -- $(getopt -q htd:f: "$@")
while [ -n "$1" ]; do
    case "$1" in
        -h) usage;;
        -t) init;getip;exit;;
        -d) init;host=${2:1:!2-1};DeleteSubDomainRecords "$host";exit;;
        -f) configfile=${2:1:!2-1};shift;;
        *);;
    esac
    shift
done

init
main
