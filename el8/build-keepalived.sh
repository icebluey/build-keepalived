#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

_install_kernel_dev() {
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _kver="6.1.37-20230704"
    wget -c -t 9 -T 9 "https://github.com/icebluey/kernel.el8/releases/download/v${_kver}/kernel-headers-${_kver}.el8.x86_64.rpm"
    wget -c -t 9 -T 9 "https://github.com/icebluey/kernel.el8/releases/download/v${_kver}/kernel-devel-${_kver}.el8.x86_64.rpm"
    yum localinstall -y kernel-headers-*.rpm
    yum localinstall -y kernel-devel-*.rpm
    sleep 2
    cd /tmp
    rm -fr "${_tmp_dir}"
}
_install_kernel_dev

CFLAGS='-O2 -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fstack-protector-strong -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection'
export CFLAGS
CXXFLAGS='-O2 -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fstack-protector-strong -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection'
export CXXFLAGS
LDFLAGS='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now'
export LDFLAGS
_ORIG_LDFLAGS="${LDFLAGS}"

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

_strip_files() {
    if [[ "$(pwd)" = '/' ]]; then
        echo
        printf '\e[01;31m%s\e[m\n' "Current dir is '/'"
        printf '\e[01;31m%s\e[m\n' "quit"
        echo
        exit 1
    else
        rm -fr lib64
        rm -fr lib
        chown -R root:root ./
    fi
    find usr/ -type f -iname '*.la' -delete
    if [[ -d usr/share/man ]]; then
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
        sleep 2
        find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
        sleep 2
        find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
        sleep 2
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
    fi
    if [[ -d usr/lib/x86_64-linux-gnu ]]; then
        find usr/lib/x86_64-linux-gnu/ -type f \( -iname '*.so' -or -iname '*.so.*' \) | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
        find usr/lib/x86_64-linux-gnu/ -iname 'lib*.so*' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
        find usr/lib/x86_64-linux-gnu/ -iname '*.so' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
    fi
    if [[ -d usr/lib64 ]]; then
        find usr/lib64/ -type f \( -iname '*.so' -or -iname '*.so.*' \) | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
        find usr/lib64/ -iname 'lib*.so*' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
        find usr/lib64/ -iname '*.so' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
    fi
    if [[ -d usr/sbin ]]; then
        find usr/sbin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
    fi
    if [[ -d usr/bin ]]; then
        find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' /usr/bin/strip '{}'
    fi
    echo
}

_build_zlib() {
    /sbin/ldconfig
    set -e
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _zlib_ver="$(wget -qO- 'https://www.zlib.net/' | grep 'zlib-[1-9].*\.tar\.' | sed -e 's|"|\n|g' | grep '^zlib-[1-9]' | sed -e 's|\.tar.*||g' -e 's|zlib-||g' | sort -V | uniq | tail -n 1)"
    wget -c -t 9 -T 9 "https://www.zlib.net/zlib-${_zlib_ver}.tar.gz"
    tar -xof zlib-*.tar.*
    sleep 1
    rm -f zlib-*.tar*
    cd zlib-*
    ./configure --prefix=/usr --libdir=/usr/lib64 --includedir=/usr/include --sysconfdir=/etc --64
    make -j2 all
    rm -fr /tmp/zlib
    make DESTDIR=/tmp/zlib install
    cd /tmp/zlib
    _strip_files
    install -m 0755 -d usr/lib64/keepalived/private
    cp -af usr/lib64/*.so* usr/lib64/keepalived/private/
    /bin/rm -f /usr/lib64/libz.so*
    /bin/rm -f /usr/lib64/libz.a
    sleep 2
    /bin/cp -afr * /
    sleep 2
    cd /tmp
    rm -fr "${_tmp_dir}"
    rm -fr /tmp/zlib
    /sbin/ldconfig
}

_build_openssl33() {
    set -e
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _openssl33_ver="$(wget -qO- 'https://openssl-library.org/source/index.html' | grep 'openssl-3\.3\.' | sed 's|"|\n|g' | sed 's|/|\n|g' | grep -i '^openssl-3\.3\..*\.tar\.gz$' | cut -d- -f2 | sed 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
    wget -c -t 9 -T 9 https://github.com/openssl/openssl/releases/download/openssl-${_openssl33_ver}/openssl-${_openssl33_ver}.tar.gz
    tar -xof openssl-*.tar*
    sleep 1
    rm -f openssl-*.tar*
    cd openssl-*
    # Only for debian/ubuntu
    #sed '/define X509_CERT_FILE .*OPENSSLDIR "/s|"/cert.pem"|"/certs/ca-certificates.crt"|g' -i include/internal/cryptlib.h
    sed '/install_docs:/s| install_html_docs||g' -i Configurations/unix-Makefile.tmpl
    LDFLAGS='' ; LDFLAGS='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,\$$ORIGIN' ; export LDFLAGS
    HASHBANGPERL=/usr/bin/perl
    ./Configure \
    --prefix=/usr \
    --libdir=/usr/lib64 \
    --openssldir=/etc/pki/tls \
    enable-ec_nistp_64_gcc_128 \
    zlib enable-tls1_3 threads \
    enable-camellia enable-seed \
    enable-rfc3779 enable-sctp enable-cms \
    enable-md2 enable-rc5 enable-ktls \
    no-mdc2 no-ec2m \
    no-sm2 no-sm3 no-sm4 \
    shared linux-x86_64 '-DDEVRANDOM="\"/dev/urandom\""'
    perl configdata.pm --dump
    make -j2 all
    rm -fr /tmp/openssl33
    make DESTDIR=/tmp/openssl33 install_sw
    cd /tmp/openssl33
    # Only for debian/ubuntu
    #mkdir -p usr/include/x86_64-linux-gnu/openssl
    #chmod 0755 usr/include/x86_64-linux-gnu/openssl
    #install -c -m 0644 usr/include/openssl/opensslconf.h usr/include/x86_64-linux-gnu/openssl/
    sed 's|http://|https://|g' -i usr/lib64/pkgconfig/*.pc
    _strip_files
    install -m 0755 -d usr/lib64/keepalived/private
    cp -af usr/lib64/*.so* usr/lib64/keepalived/private/
    rm -fr /usr/include/openssl
    rm -fr /usr/include/x86_64-linux-gnu/openssl
    rm -fr /usr/local/openssl-1.1.1
    rm -f /etc/ld.so.conf.d/openssl-1.1.1.conf
    sleep 2
    /bin/cp -afr * /
    sleep 2
    cd /tmp
    rm -fr "${_tmp_dir}"
    rm -fr /tmp/openssl33
    /sbin/ldconfig
}

rm -fr /usr/lib64/keepalived
#_build_zlib
_build_openssl33

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
/sbin/ldconfig
_keepalived_ver="$(wget -qO- 'https://www.keepalived.org/download.html' | grep -i 'keepalived-[1-9].*\.tar' | sed -e 's|"|\n|g' -e 's|/|\n|g' | grep -i '^keepalived-[1-9].*\.tar' | sed -e 's|keepalived-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://www.keepalived.org/software/keepalived-${_keepalived_ver}.tar.gz"
tar -xof keepalived-*.tar*
sleep 1
rm -f keepalived-*.tar*
cd keepalived-*
LDFLAGS='' ; LDFLAGS="${_ORIG_LDFLAGS}"' -Wl,-rpath,/usr/lib64/keepalived/private' ; export LDFLAGS
./configure \
--build=x86_64-linux-gnu \
--host=x86_64-linux-gnu \
--prefix=/usr \
--sysconfdir=/etc \
--enable-snmp \
--enable-snmp-rfc \
--enable-nftables \
--disable-iptables \
--with-init=systemd
make -j2 all
rm -fr /tmp/keepalived
sleep 2
make DESTDIR=/tmp/keepalived install
cd /tmp/keepalived
rm -fr usr/lib
rm -fr lib
rm -fr lib64
install -m 0755 -d var/log/keepalived
install -m 0755 -d usr/libexec/keepalived
[[ -f etc/keepalived/keepalived.conf ]] && mv -f etc/keepalived/keepalived.conf etc/keepalived/keepalived.conf.default
mv -f etc/keepalived/samples usr/share/doc/keepalived/
#install -m 0755 -d usr/lib64/keepalived
#cp -af /usr/lib64/keepalived/private usr/lib64/keepalived/
install -m 0755 -d usr/lib64/keepalived/private
cp -af \
/usr/local/private/libz.so* \
/usr/local/private/libssl.so* \
/usr/local/private/libcrypto.so* \
usr/lib64/keepalived/private/
strip usr/sbin/keepalived
find -L usr/share/man/ -type l -exec rm -f '{}' \;
sleep 2
find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
sleep 2
find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
sleep 2
find -L usr/share/man/ -type l -exec rm -f '{}' \;

echo '[Unit]
Description=LVS and VRRP High Availability Monitor
After=network-online.target syslog.target
Wants=network-online.target

[Service]
Type=notify
NotifyAccess=all
PIDFile=/run/keepalived.pid
KillMode=process
EnvironmentFile=-/etc/sysconfig/keepalived
ExecStart=/usr/sbin/keepalived --dont-fork $KEEPALIVED_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target' > etc/keepalived/keepalived.service
sleep 1
chmod 0644 etc/keepalived/keepalived.service

echo '
cd "$(dirname "$0")"
systemctl daemon-reload >/dev/null 2>&1 || : 
rm -f /lib/systemd/system/keepalived.service
install -v -c -m 0644 keepalived.service /lib/systemd/system/
systemctl daemon-reload >/dev/null 2>&1 || : 
[[ -d /var/log/keepalived ]] || install -m 0755 -d /var/log/keepalived
[[ -f /var/log/keepalived/keepalived.log ]] || cat /dev/null > /var/log/keepalived/keepalived.log
echo '\'':programname, startswith, "Keepalived" {
    /var/log/keepalived/keepalived.log
    stop
}'\'' >/etc/rsyslog.d/10-keepalived.conf
echo '\''/var/log/keepalived/*log {
    daily
    rotate 62
    dateext
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /usr/bin/killall -HUP rsyslogd 2> /dev/null || true
        /usr/bin/killall -HUP syslogd 2> /dev/null || true
    endscript
}'\'' >/etc/logrotate.d/keepalived
sleep 1
systemctl restart rsyslog.service >/dev/null 2>&1 || : 
systemctl restart logrotate.service >/dev/null 2>&1 || : 
' > etc/keepalived/.install.txt
chmod 0644 etc/keepalived/.install.txt
echo
sleep 2
tar -Jcvf /tmp/"keepalived-${_keepalived_ver}-1.el8.x86_64.tar.xz" *
echo
sleep 2
cd /tmp
sha256sum "keepalived-${_keepalived_ver}-1.el8.x86_64.tar.xz" > "keepalived-${_keepalived_ver}-1.el8.x86_64.tar.xz".sha256
cd /tmp
rm -fr /tmp/keepalived
rm -fr "${_tmp_dir}"
sleep 2
echo
echo ' build keepalived el8 done'
echo
/sbin/ldconfig
exit
