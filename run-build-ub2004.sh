#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
set -e
systemctl start docker
sleep 5
docker run --cpus="2.0" --rm --name ub2004 -itd ubuntu:20.04 bash
sleep 2
docker exec ub2004 apt update -y
docker exec ub2004 apt upgrade -fy
docker exec ub2004 apt install -y bash vim wget ca-certificates libnftables-dev nftables libipset-dev ipset iptables libsnmp-dev libmnl-dev libnftnl-dev libnl-3-dev libnl-genl-3-dev libnfnetlink-dev
docker exec ub2004 /bin/ln -svf bash /bin/sh
docker exec ub2004 /bin/rm -fr /tmp/.setup_env_ub2004
docker exec ub2004 wget -q "https://raw.githubusercontent.com/icebluey/build/master/.setup_env_ub2004" -O "/tmp/.setup_env_ub2004"
docker exec ub2004 /bin/bash /tmp/.setup_env_ub2004
docker exec ub2004 /bin/rm -f /tmp/.setup_env_ub2004
docker exec ub2004 /bin/bash -c '/bin/rm -fr /tmp/*'
docker cp ub2004 ub2004:/home/
docker exec ub2004 /bin/bash /home/ub2004/build-keepalived-quictls.sh
_keepalived_ver="$(docker exec ub2004 ls -1 /tmp/ | grep -i '^keepalived.*xz$' | sed -e 's|keepalived-||g' -e 's|-[0-1]_amd64.*||g')"
rm -fr /home/.tmp.keepalived
mkdir /home/.tmp.keepalived
docker cp ub2004:/tmp/keepalived-"${_keepalived_ver}"-1_amd64.tar.xz /home/.tmp.keepalived/
docker cp ub2004:/tmp/keepalived-"${_keepalived_ver}"-1_amd64.tar.xz.sha256 /home/.tmp.keepalived/
exit
