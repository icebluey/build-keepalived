#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
set -e
cd "$(dirname "$0")"
systemctl start docker
sleep 5
echo
cat /proc/cpuinfo
echo
if [ "$(cat /proc/cpuinfo | grep -i '^processor' | wc -l)" -gt 1 ]; then
    docker run --cpus="$(cat /proc/cpuinfo | grep -i '^processor' | wc -l).0" --rm --name al9 -itd almalinux:9 bash
else
    docker run --rm --name al9 -itd almalinux:9 bash
fi
sleep 2
docker exec al9 dnf clean all
docker exec al9 dnf makecache
docker exec al9 dnf install -y wget bash
docker exec al9 /bin/bash -c 'ln -svf bash /bin/sh'
docker exec al9 /bin/bash -c 'rm -fr /tmp/*'
docker cp al9 al9:/home/
docker exec al9 /bin/bash /home/al9/install-kernel.sh
docker exec al9 /bin/bash /home/al9/.preinstall_al9
docker exec al9 /bin/bash /home/al9/build-keepalived.sh
_keepalived_ver="$(docker exec al9 ls -1 /tmp/ | grep -i '^keepalived.*xz$' | sed -e 's|keepalived-||g' -e 's|-[0-1].el.*||g')"
mkdir -p /tmp/_output.tmp
docker cp al9:/tmp/keepalived-"${_keepalived_ver}"-1_el9_amd64.tar.xz /tmp/_output.tmp/
docker cp al9:/tmp/keepalived-"${_keepalived_ver}"-1_el9_amd64.tar.xz.sha256 /tmp/_output.tmp/
exit
