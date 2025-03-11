#!/bin/bash

setup() {
    name="v2ray_dat_update"
    desc="update dat file from Loyalsoldier/v2ray-rules-dat."
}

main() {
    download
    [[ $? == 2 ]] && move && echo "V2ray dat file update done!" || echo "V2ray date file update failed."
}

download() {
    echo start download
    # 获取下载链接
    result=$(curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | grep browser_download_url)
    down=$HOME/Downloads
    num=0
    for str in $result ; do
        [[ ${str:0-1:1} == ":" ]] && continue
        url=${str%\"}
        url=${url##*\"}
        [[ ${url##*/} == "geoip.dat" ]] && wget -O $down/geoip.dat.new ${url} && num=$(expr $num + 1)
        [[ ${url##*/} == "geosite.dat" ]] && wget -O $down/geosite.dat.new ${url} && num=$(expr $num + 1)
    done
    [[ "$num" == "2" ]] && echo "download successful" || echo "download failed"
    return $num
}

move() {
    [[ $(whoami) == "root" ]] || {
        echo "user $(whoami), cannot move."
        rm $dwon/geoip.dat.new
        rm $down/geosite.dat.new
        return 1
    }
    [[ -f geoip.dat ]] && {
        [[ -f backup/geoip.dat.bak ]] && rm backup/geoip.dat.bak
        mv geoip.dat backup/geoip.dat.bak
    }
    mv $down/geoip.dat.new geoip.dat
    [[ -f geosite.dat ]] && {
        [[ -f backup/geosite.dat.bak ]] && rm backup/geosite.dat.bak
        mv geosite.dat backup/geosite.dat.bak
    }
    mv $down/geosite.dat.new geosite.dat
}

init() {
    cd /usr/share/v2ray/
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
