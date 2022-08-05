# Delpoy DNS server(macos)
## Install

```
brew install bind
```



## Config file

### Place

file: named.conf

ps: my path: /opt/homebrew/etc/bind/named.conf

If you can not find it, you can use cmd to search this:

```
sudo find /  -name named.conf
```



### Common 

```
logging {
    category default {
        _default_log;
    };
    channel _default_log {
        file "/opt/homebrew/var/log/named/named.log" versions 10 size 1m;
        severity info;
        print-time yes;
    };
};

options {
    directory "/opt/homebrew/var/named";
    //dnssec-enable yes;
    //dnssec-validation auto;
    //dnssec-lookaside auto;
    notify yes;
    allow-transfer { none; };
};
```



### Config zone

named.conf

```
zone "bindnosec.cn" IN {
    type master;
    auto-dnssec maintain;
    update-policy local;
    file "/opt/homebrew/etc/bind/views/zones/bindnosec.cn.zone";
};
```



bindnosec.cn.zone

place: /opt/homebrew/etc/bind/views/zones/bindnosec.cn.zone

```
$TTL 1D
@   IN    SOA    bindnosec.cn    admin.bindnosec.cn. (
        0       ; serial
        1D      ; refresh
        1H      ; retry
        1W      ; expire
        3H )    ; minimum

    NS  ns.bindnosec.cn.
@       A   10.64.XX.XX
ns      A   10.64.XX.XX
www     A   10.64.XX.XX
```

ps: use related website ip to replace 10.64.XX.XX



## Run bind services with root

```
brew services start bind

brew service restart bind

brew services stop bind
```



## Test

dig

```
dig  www.bindnosec.cn @127.0.0.1
```

nslookup

```
nslookup bindnosec 127.0.0.1
```



## Troubeshooting

If can not start bind services successfully, you can check the named.log, whose path can be found from named.conf.

my named.log: /opt/homebrew/var/log/named/named.log



# DNSSEC config

## config

bindsec.cn.zone

place: "/opt/homebrew/etc/bind/views/zones/bindsec.cn.zone

```
$TTL 1D
@   IN    SOA    bindsec.cn    admin.bindsec.cn. (
        0       ; serial
        1D      ; refresh
        1H      ; retry
        1W      ; expire
        3H )    ; minimum

    NS  ns.bindsec.cn.
@       A   10.64.XX.XX
ns      A   10.64.XX.XX
www     A   10.64.XX.XX
```



## Sign(with root)

### gen key

```shell
cd /opt/homebrew/etc/bind/views
mkdir dnssec_keys
cd dnssec_keys
# gen dns key:KSK and ZSK, ref dnssec-keygen doc

dnssec-keygen -f KSK -a RSASHA1 -b 1024 -n ZONE bindsec.cn
dnssec-keygen -a RSASHA1  -b 1024 -n ZONE bindsec.cn


```

It will gen 4 keys file

```
Kbindsec.cn.+005+38991.key
Kbindsec.cn.+005+38991.private
Kbindsec.cn.+005+50497.key
Kbindsec.cn.+005+50497.private
```



Add these two public key(.key) file to  bindsec.cn.zone as following

```
$TTL 1D
@   IN    SOA    bindsec.cn    admin.bindsec.cn. (
        0       ; serial
        1D      ; refresh
        1H      ; retry
        1W      ; expire
        3H )    ; minimum

    NS  ns.bindsec.cn.
@       A   10.64.XX.XX
ns      A   10.64.XX.XX
www     A   10.64.XX.XX

$INCLUDE "/opt/homebrew/etc/bind/views/dnssec_keys/Kbindsec.cn.+005+38991.key"
$INCLUDE "/opt/homebrew/etc/bind/views/dnssec_keys/Kbindsec.cn.+005+50497.key"
```



### sign for zone

```
dnssec-signzone -K /opt/homebrew/etc/bind/views/dnssec_keys -o bindsec.cn. /opt/homebrew/etc/bind/views/zones/bindsec.cn.zone
```

It will gen 1 sign file

```
bindsec.cn.zone.signed
```



### gen trust anchor

check the content of two public key files

```
$cat Kbindsec.cn.+005+38991.key
; This is a zone-signing key, keyid 38991, for bindsec.cn.
; Created: 20220805031455 (Fri Aug  5 11:14:55 2022)
; Publish: 20220805031455 (Fri Aug  5 11:14:55 2022)
; Activate: 20220805031455 (Fri Aug  5 11:14:55 2022)
bindsec.cn. IN DNSKEY 256 3 5 AwEAAaQiEbEVgv/VWiHTkOVROCjrZt5U7MfD3qRy6XYG4MUuqBhb3EZ7 Hreu5hFk7jRJDSAX3//mTpR/1aFCFMUVQEaKZDwdkAaziiPJMnzhDvB+ 6lo065AzHZdooAmpbQGZhpLeUlr/xCk8IL7+mySJfRMSxTgdjvEJXdUW TqsYbkeP

$cat Kbindsec.cn.+005+50497.key
; This is a key-signing key, keyid 50497, for bindsec.cn.
; Created: 20220805031440 (Fri Aug  5 11:14:40 2022)
; Publish: 20220805031440 (Fri Aug  5 11:14:40 2022)
; Activate: 20220805031440 (Fri Aug  5 11:14:40 2022)
bindsec.cn. IN DNSKEY 257 3 5 AwEAAc+EdB1F2jtrCkz2tBKY4OMSN1gGz1at0S5Ou3RYjrXQGwLwJmPO vAgH4cX/RtuDH/XmK873DLc2RA+weFaMIOU6oj0K/272DxxB7UGCZdgi ljahkpDR8Xi5OwGe3px+YxXMLuZxggCk2JixcToTo6SVWEksw9d5KVcP cC2dCuTx

```

 ```
 cd /opt/homebrew/etc/bind/
 touch sec-trust-anchors.conf
 ```



edit  sec-trust-anchors.conf

copy the public key here , then "bindsec.cn", remove IN DNSKEY,  "key"

```
trust-anchors {
	"bindsec.cn." initial-key 256 3 5 "AwEAAaQiEbEVgv/VWiHTkOVROCjrZt5U7MfD3qRy6XYG4MUuqBhb3EZ7 Hreu5hFk7jRJDSAX3//mTpR/1aFCFMUVQEaKZDwdkAaziiPJMnzhDvB+ 6lo065AzHZdooAmpbQGZhpLeUlr/xCk8IL7+mySJfRMSxTgdjvEJXdUW TqsYbkeP";
	"bindsec.cn." initial-key 257 3 5 "AwEAAc+EdB1F2jtrCkz2tBKY4OMSN1gGz1at0S5Ou3RYjrXQGwLwJmPO vAgH4cX/RtuDH/XmK873DLc2RA+weFaMIOU6oj0K/272DxxB7UGCZdgi ljahkpDR8Xi5OwGe3px+YxXMLuZxggCk2JixcToTo6SVWEksw9d5KVcP cC2dCuTx";
};

```



add bindsec.cn zone in named.conf

```
zone "bindsec.cn" IN {
    type master;
    auto-dnssec maintain;
    update-policy local;
    file "/opt/homebrew/etc/bind/views/zones/bindsec.cn.zone.signed";
    key-directory "/opt/homebrew/etc/bind/views/dnssec_keys";
};

include "/opt/homebrew/etc/bind/sec-trust-anchors.conf";
```



### test

```
dig +dnssec bindsec.cn @127.0.0.1
```



# Verify from browser

## deploy server

run apache server on the pc, which ip is 10.64.XX.XX

```
 apachectl start
```

## Veify

visit 10.64.XX.XX from browser

visit bindnosec.cn from browser

visit bindsec.cn from browser
