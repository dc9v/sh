#!/bin/bash

echo "아직 완성하지 않았습니다"
echo "Not finished yet!"
exit

# DISCLAIMER
#
# This script automatically backup current setting files

# OpenVPN Server key generator.
#
#   This script This script can be used to generates keys for OpenVPN clients.
#   Also generates .ovpn file so that it can be publish to clients.

# Required
#
#   - OpenVPN/easy-rsa https://github.com/OpenVPN/easy-rsa
#

OPENVPN_PATH=/etc/openvpn
EASYRSA_PATH=$OPENVPN_PATH/easy-rsa
BACKUP_DIR=.backup
BACKUP_NAME=$(date +%Y)$(date +%m)$(date +%d)$(date +%H)$(date +%M)$(date +%S)

if [ -z "$1" ]
then
    echo
    echo "Useage: ./install-easy-rsa-and-generate-server-key [servername or domain]"
    echo ; echo
    exit
fi

if [ $EUID -ne 0 ]; then
    echo "Please re-run as root via sudo."
    exit
fi

# Install EasyRSA
apt install openvpn easy-rsa -y


# Initialize directories
mkdir -p /etc/openvpn/server
mkdir -p /etc/openvpn/client
make-cadir /etc/openvpn/easy-rsa


## Backup old PKI
if [ -d "$EASYRSA_PATH/pki" ]; then
    mkdir -p $EASYRSA_PATH/$BACKUP_DIR/$BACKUP_NAME
    mv $EASYRSA_PATH/* $EASYRSA_PATH/$BACKUP_DIR/$BACKUP_NAME
fi


# Generate req, key
./easyrsa init-pki
echo -en "$1\n"  | ./easyrsa build-ca nopass
echo -en "yes\n"  | ./easyrsa sign-req server $1


# Generate req, key
if [ -f "$OPENVPN_PATH/server.conf" ]; then
    mkdir -p $OPENVPN_PATH/$BACKUP_DIR
    mv $OPENVPN_PATH/server.conf $OPENVPN_PATH/$BACKUP_DIR/$BACKUP_NAME.server.conf.bak
fi


cp $OPENVPN_PATH/server/server-example.conf cp $OPENVPN_PATH/server.conf
