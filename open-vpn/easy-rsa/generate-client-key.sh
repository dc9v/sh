#!/bin/bash

OPENVPN_PATH=/etc/openvpn
CLIENT_KEY_STORE=$OPENVPN_PATH/client/keys
EASYRSA_PATH=$OPENVPN_PATH/easy-rsa
SAMPLE_CONF=$OPENVPN_PATH/client/client-sample.ovpn
OVPN_EXPORT=$OPENVPN_PATH/client/ovpn
DEST=$OVPN_EXPORT/$1.ovpn

if [ -z "$1" ]; then
    echo
    echo "Useage: ./generate-client-key.sh [username]"
    echo ; echo
    exit
fi

if [ $EUID -ne 0 ]; then
    echo "Please re-run as root via sudo."
    exit
fi

# Export directories initialize
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

# Generate cert
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
