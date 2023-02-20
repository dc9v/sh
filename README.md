| ⛔ 위험. 아직 완성되지 않은 쉘 스크립트입니다! 실행 시 당신의 시스템이 망가질 수 있습니다. |
|:---:|

# openvpn

openvpn 설정에 대한 문서입니다.

## 설치하기

아래 명령으로 설치하거나 [install-openvpn.sh](#shellscript-install-openvpn-sh) 스크립트를 사용해서 설치하세요.

```sh
sudo update
sudo apt install openvpn easy-rsa
```

## Template

*template/vars.sample*

```apacheconf
# Easy-RSA 3 parameter settings

# NOTE: If you installed Easy-RSA from your distro's package manager, don't edit
# this file in place -- instead, you should copy the entire easy-rsa directory
# to another location so future upgrades don't wipe out your changes.

if [ -z "$EASYRSA_CALLER" ]; then
        echo "You appear to be sourcing an Easy-RSA 'vars' file." >&2
        echo "This is no longer necessary and is disallowed. See the section called" >&2
        echo "'How to use this file' near the top comments for more details." >&2
        return 1
fi

## Please update the below variables
set_var EASYRSA_REQ_COUNTRY     "[EASYRSA_REQ_COUNTRY]"
set_var EASYRSA_REQ_PROVINCE    "[EASYRSA_REQ_PROVINCE]"
set_var EASYRSA_REQ_CITY        "[EASYRSA_REQ_CITY]"
set_var EASYRSA_REQ_ORG         "[EASYRSA_REQ_ORG]"
set_var EASYRSA_REQ_EMAIL       "[EASYRSA_REQ_EMAIL]"
set_var EASYRSA_REQ_OU          "[EASYRSA_REQ_OU]"


# Optional variables
set_var EASYRSA_ALGO           rsa      # rsa, ec
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_CA_EXPIRE      3650     # 365 = 1year
set_var EASYRSA_CERT_EXPIRE    3650     # 365 = 1year
#set_var EASYRSA_CURVE         secp384r1

```

*template/server.conf.sample*

```apacheconf
;local a.b.c.d
port 9000

;proto udp
proto tcp

;dev tap
;dev-node MyTap
dev tun

ca [EASYRSA_PKI_PATH]/ca.crt
key [EASYRSA_PKI_PATH]/private/balsa.to.key
cert [EASYRSA_PKI_PATH]/issued/balsa.to.crt
dh [EASYRSA_PKI_PATH]/dh.pem

;topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

;server-bridge 10.8.0.4 255.255.255.0 10.8.0.50 10.8.0.100
;server-bridge
;push "route 192.168.20.0 255.255.255.0"
push "route 192.168.10.0 255.255.255.0"

;client-config-dir ccd
;route 192.168.40.128 255.255.255.248
;client-config-dir ccd
;route 10.9.0.0 255.255.255.252
;learn-address ./script

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"

;client-to-client
;duplicate-cn
keepalive 10 120

tls-auth [EASYRSA_PATH]/tls-auth.key 0
key-direction 0

cipher AES-256-CBC
auth SHA256

;compress lz4-v2
;push "compress lz4-v2"
comp-lzo

max-clients 20
user nobody
group nogroup

persist-key
persist-tun

status /var/log/openvpn/openvpn-status.log
log         /var/log/openvpn/openvpn.log
log-append  /var/log/openvpn/openvpn.log

;mute 20
verb 3
explicit-exit-notify 0
```

## ShellScript

<div id="shellscript-install-openvpn-sh" />

*install-openvpn.sh*

```sh
OPENVPN_PATH=/etc/openvpn
EASYRSA_PATH=$OPENVPN_PATH/easyrsa
EASYRSA_PKI_PATH=$EASYRSA_PATH/pki
BACKUP_DIR=.backup
BACKUP_NAME=$(date +%Y)$(date +%m)$(date +%d)$(date +%H)$(date +%M)$(date +%S)
REQUIRED_COMMANDS=( "make-cadir" "openvpn" )

if [ -z "$1" ]
then
    echo
    echo "Usage: install-openvpn.sh [servername or domain]"
    echo ; echo
    exit
fi

if [ $EUID -ne 0 ]; then
    echo "Please re-run as root via sudo."
    exit
fi

apt update

apt install openvpn easy-rsa -y

for CMD in ${REQUIRED_COMMANDS[@]}; do
    if ! command -v $CMD &> /dev/null
    then
        echo "[${CMD}] Command not found."
        exit
    fi
done

enter_attributes:

EASYRSA_REQ=( "EASYRSA_REQ_COUNTRY" "EASYRSA_REQ_PROVINCE" "EASYRSA_REQ_CITY" "EASYRSA_REQ_ORG" "EASYRSA_REQ_EMAIL" "EASYRSA_REQ_OU")
EASYRSA_REQ_DEFAULT=( "CA" "British Columbia" "Vancouver" "International VPN Ltd" "" "" )

echo ;
echo -e "\033[1m\e[33mPlease enter the following attributes:\e[0m"
read -p "   Country Name (2 letter code) [CA]: " EASYRSA_REQ_COUNTRY
read -p "   State or Province Name (full name) [British Columbia]: " EASYRSA_REQ_PROVINCE
read -p "   Locality Name (eg, city) [Vancouver]: " EASYRSA_REQ_CITY
read -p "   Organization Name (eg, company) [International VPN Ltd]: " EASYRSA_REQ_ORG
read -p "   Email Address []: " EASYRSA_REQ_EMAIL
read -p "   Common Name (eg, YOUR name) []: " EASYRSA_REQ_OU
echo ;

i=0
for REQ in ${EASYRSA_REQ[@]}; do
  REQ_VAR=$(echo ${!REQ} | sed 's/ *$//g')
  if [ -z "$REQ_VAR" ]; then
    declare $REQ=${EASYRSA_REQ_DEFAULT[$i]}
    echo "$REQ = '$REQ_VAR'"
  fi
i=$i+1
done

for REQ in ${EASYRSA_REQ[@]}; do
  if [ -z "$REQ_VAR" ]; then
    echo "[$REQ] attribute empty."
    echo "Please enter the following attributes again."
    jumpto enter_attributes
  fi
done


mkdir -p $OPENVPN_PATH
make-cadir $EASYRSA_PATH

cd $EASYRSA_PATH && ./easyrsa init-pki

cd $EASYRSA_PATH && echo -en "$1\n" | ./easyrsa build-ca nopass
cd $EASYRSA_PATH && echo -en "yes\n" | ./easyrsa sign-req server $1

cp -f template/server.conf.sample $OPENVPN_PATH/server.conf

sed -i "s|\[EASYRSA_PKI_PATH\]|$EASYRSA_PKI_PATH|" $OPENVPN_PATH/server.conf
sed -i "s|\[EASYRSA_PATH\]|$EASYRSA_PATH|" $OPENVPN_PATH/server.conf

```


*/etc/openvpn/client/client-ovpn.ovpn*

```apacheconf
;https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/

client
dev tun

;proto udp
proto tcp

;remote [remote-host] [port]
remote vpn.proxy.balsa.to 9000

;resolv-retry 10
resolv-retry 10

nobind

persist-key
persist-tun
persist-remote-ip

remote-cert-tls server
cipher AES-256-CBC
auth SHA256

comp-lzo
```

*/etc/openvpn/client/generate-client-key.sh*

```sh
#!/bin/bash

# OpenVPN Client key generator.
#
# @author Taegyun Ko<dev@balsa.to>
# @since 2022-12-29
#
# This script This script can be used to generates keys for OpenVPN clients.
# Also generates .ovpn file so that it can be publish to clients.

# Required
#   1. OpenVPN/easy-rsa: https://github.com/OpenVPN/easy-rsa

OPENVPN_PATH=/etc/openvpn
USER_HOME=$(getent passwd $1 | cut -f6 -d:)
CLIENT_KEY_STORE=$OPENVPN_PATH/client/keys
EASYRSA_PATH=$OPENVPN_PATH/easy-rsa
SAMPLE_CONF=$OPENVPN_PATH/client/client-sample.ovpn
OVPN_EXPORT=$USER_HOME/openvpn/
DEST=$OVPN_EXPORT/$1.ovpn

if [ -z "$1" ]; then
  echo
  echo "Usage: generate-client-key.sh [username]"
  echo ; echo
  exit
fi

if [ $EUID -ne 0 ]; then
  echo "Please re-run as root via sudo."
  exit
fi

if ! id $1 > /dev/null 2>&1; then
  echo "[$1] Username not found."
  exit
fi

if [ -d "$CLIENT_KEY_STORE" ]; then
  mkdir -p $CLIENT_KEY_STORE
fi

if [ -d "$CLIENT_KEY_STORE/$1" ]; then
  mkdir -p $CLIENT_KEY_STORE/$1
fi

if [ -d "$OVPN_EXPORT" ]; then
  mkdir -p $OVPN_EXPORT
fi

# Generate req, key
if [ -f "$EASYRSA_PATH/pki/private/$1.key" ]; then
  echo -en "yes\n$1\n" | $EASYRSA_PATH/easyrsa gen-req $1 nopass
else
  echo -en "$1\n"  | $EASYRSA_PATH/easyrsa gen-req $1 nopass
fi

echo -en "yes\n" | $EASYRSA_PATH/easyrsa sign-req client $1

# Copy keys
cp $EASYRSA_PATH/pki/reqs/$1.req $CLIENT_KEY_STORE/$1
cp $EASYRSA_PATH/pki/private/$1.key $CLIENT_KEY_STORE/$1
cp $EASYRSA_PATH/pki/issued/$1.crt $CLIENT_KEY_STORE/$1

echo "" > $DEST
cat $SAMPLE_CONF >> $DEST

echo "<ca>" >> $DEST
cat $EASYRSA_PATH/pki/ca.crt >> $DEST
echo "</ca>" >> $DEST

echo "<cert>" >> $DEST
cat $CLIENT_KEY_STORE/$1/$1.crt >> $DEST
echo "</cert>" >> $DEST

echo "<key>" >> $DEST
cat $CLIENT_KEY_STORE/$1/$1.key >> $DEST
echo "</key>" >> $DEST

echo "<tls-auth>" >> $DEST
cat $EASYRSA_PATH/tls-auth.key >> $DEST
echo "</tls-auth>" >> $DEST


```
