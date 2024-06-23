## Master
#### /etc/keepalived/keepalived.conf
```
global_defs {
    router_id k8s
    vrrp_mcast_group4 224.0.0.18
}
vrrp_script check_haproxy {
    script "/usr/bin/bash -c 'if [[ $(ps -C haproxy --no-header | wc -l) -eq 0 ]] ; then exit 1;fi'"
    interval 3
    weight -30
    fall 2
    rise 5
    timeout 3
}
vrrp_instance vi1 {
    state MASTER
    virtual_router_id 100
    priority 120
    nopreempt
    garp_master_delay 1
    garp_master_refresh 5
    advert_int 1
    interface ens160
    authentication {
        auth_type PASS
        auth_pass abcd1234
    }
    virtual_ipaddress {
        192.168.10.10 dev ens160
    }
    unicast_src_ip 192.168.10.101
    unicast_peer {
        192.168.10.102
        192.168.10.103
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
    router_id k8s
    vrrp_mcast_group4 224.0.0.18
}
vrrp_script check_haproxy {
    script "/usr/bin/bash -c 'if [[ $(ps -C haproxy --no-header | wc -l) -eq 0 ]] ; then exit 1;fi'"
    interval 3
    weight -30
    fall 2
    rise 5
    timeout 3
}
vrrp_instance vi1 {
    state BACKUP
    virtual_router_id 100
    priority 120
    preempt
    garp_master_delay 1
    garp_master_refresh 5
    advert_int 1
    interface ens160
    authentication {
        auth_type PASS
        auth_pass abcd1234
    }
    virtual_ipaddress {
        192.168.10.10 dev ens160
    }
    unicast_src_ip 192.168.10.102
    unicast_peer {
        192.168.10.101
        192.168.10.103
    }
    track_script {
        check_haproxy
    }
}
```
