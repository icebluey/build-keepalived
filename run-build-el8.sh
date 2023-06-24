#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
set -e
systemctl start docker
sleep 5
docker run --cpus="2.0" --hostname 'x86-034.build.eng.bos.redhat.com' --rm --name al8 -itd icebluey/almalinux:8 bash
sleep 2
docker exec al8 yum clean all
docker exec al8 yum makecache
#docker exec al8 yum install -y bash vim wget ca-certificates
#docker exec al8 /bin/ln -svf bash /bin/sh
#docker exec al8 /bin/rm -fr /tmp/.runme.sh
#docker exec al8 /bin/rm -fr /tmp/yum.log
#docker exec al8 wget -q "https://raw.githubusercontent.com/icebluey/pre-build/master/el8/.preinstall-el8" -O /tmp/.runme.sh
#docker exec al8 /bin/bash /tmp/.runme.sh
#docker exec al8 /bin/rm -f /tmp/.runme.sh
docker exec al8 /bin/bash -c 'rm -fr /tmp/*'
docker cp el8 al8:/home/
docker exec al8 /bin/bash /home/el8/build-keepalived-quictls.sh
_keepalived_ver="$(docker exec al8 ls -1 /tmp/ | grep -i '^keepalived.*xz$' | sed -e 's|keepalived-||g' -e 's|-[0-1]\.el.*||g')"
rm -fr /home/.tmp.keepalived
mkdir /home/.tmp.keepalived
docker cp al8:/tmp/keepalived-"${_keepalived_ver}"-1.el8.x86_64.tar.xz /home/.tmp.keepalived/
docker cp al8:/tmp/keepalived-"${_keepalived_ver}"-1.el8.x86_64.tar.xz.sha256 /home/.tmp.keepalived/
exit
