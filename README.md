
### run
```
# el8 / el9
dnf install -y libnl3 libnftnl libmnl net-snmp-agent-libs net-snmp-libs file-libs systemd-libs
dnf install -y ipvsadm iproute nftables
#dnf install -y iptables iptables-libs iptables-ebtables ipset ipset-libs

# ubuntu 20.04 / 22.04
apt install -y libnl-3-200 libnl-genl-3-200 libnftnl11 libmnl0 libsnmp35 libsystemd0 libip4tc2 libip6tc2
apt install -y ipvsadm iproute2 iptables ipset ebtables

```

## Master
#### /etc/keepalived/keepalived.conf
```
global_defs {
    router_id k8s-master1
    enable_script_security
    script_user root
    vrrp_mcast_group4 224.0.0.18
}
vrrp_script check_haproxy {
    script "/usr/bin/bash -c 'if [[ $(ps -C haproxy --no-headers | wc -l) -eq 0 ]] ; then exit 1;fi'"
    interval 5
    weight -30
    fall 3
    rise 5
    timeout 5
}
vrrp_instance vi1 {
    state MASTER
    virtual_router_id 100
    priority 120
    nopreempt
    garp_master_delay 1
    garp_master_refresh 2
    advert_int 1
    interface ens160
    authentication {
        auth_type PASS
        auth_pass abcd1234
    }
    virtual_ipaddress {
        192.168.10.100
    }
    track_script {
        check_haproxy
    }
}
```


## Backup
#### /etc/keepalived/keepalived.conf
```
global_defs {
    router_id k8s-master2
    enable_script_security
    script_user root
    vrrp_mcast_group4 224.0.0.18
}
vrrp_script check_haproxy {
    script "/usr/bin/bash -c 'if [[ $(ps -C haproxy --no-headers | wc -l) -eq 0 ]] ; then exit 1;fi'"
    interval 5
    weight -30
    fall 3
    rise 5
    timeout 5
}
vrrp_instance vi1 {
    state BACKUP
    virtual_router_id 100
    priority 120
    preempt
    garp_master_delay 1
    garp_master_refresh 2
    advert_int 1
    interface ens160
    authentication {
        auth_type PASS
        auth_pass abcd1234
    }
    virtual_ipaddress {
        192.168.10.100
    }
    track_script {
        check_haproxy
    }
}
```
