#!/bin/bash

check_ip() {
    echo "ipinfo: $(curl --connect-timeout 3 -s https://ipinfo.io/ip)"
    echo "dedyn: $(curl --connect-timeout 3 -s https://checkipv4.dedyn.io)"
    echo "ipify_v6: $(curl --connect-timeout 3 -s https://api6.ipify.org)"
    echo "ifconfig: $(curl --connect-timeout 3 -s https://ifconfig.me/ip)"
    echo "ipecho: $(curl --connect-timeout 3 -s https://ipecho.net/plain)"
    echo "ipify: $(curl --connect-timeout 3 -s https://api.ipify.org)"
    #echo "icanhazip: $(curl --connect-timeout 3 -s https://icanhazip.com)"
    #echo "ipcn: $(curl --connect-timeout 3 -s https://www.ip.cn/api/index\?ip\&type\=0 | jq -r '.ip')"
    #echo "amazonaws: $(curl --connect-timeout 3 -s https://checkip.amazonaws.com)"
}

check_ip