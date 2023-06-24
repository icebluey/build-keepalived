#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
set -e
systemctl start docker
sleep 5
docker run --cpus="2.0" --hostname 'x86-034.build.eng.bos.redhat.com' --rm --name c7 -itd centos:7 bash
sleep 2
docker exec c7 yum clean all
docker exec c7 yum makecache fast
docker exec c7 yum install -y deltarpm bash vim wget ca-certificates
docker exec c7 /bin/ln -svf bash /bin/sh
docker exec c7 /bin/rm -fr /tmp/.runme.sh
docker exec c7 wget -q "https://raw.githubusercontent.com/icebluey/setup-env/master/runme.sh" -O /tmp/.runme.sh
docker exec c7 /bin/bash /tmp/.runme.sh
docker exec c7 /bin/rm -f /tmp/.runme.sh
docker exec c7 /bin/bash -c '/bin/rm -fr /tmp/*'
docker cp el7 c7:/home/
docker exec c7 /bin/bash /home/el7/build-keepalived-quictls.sh
_keepalived_ver="$(docker exec c7 ls -1 /tmp/ | grep -i '^keepalived.*xz$' | sed -e 's|keepalived-||g' -e 's|-[0-1]\.el.*||g')"
rm -fr /home/.tmp.keepalived
mkdir /home/.tmp.keepalived
docker cp c7:/tmp/keepalived-"${_keepalived_ver}"-1.el7.x86_64.tar.xz /home/.tmp.keepalived/
docker cp c7:/tmp/keepalived-"${_keepalived_ver}"-1.el7.x86_64.tar.xz.sha256 /home/.tmp.keepalived/
exit
