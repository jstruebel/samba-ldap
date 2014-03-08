#!/bin/bash -e

fatal() {
    echo "fatal: $@" 1>&2
    exit 1
}

usage() {
cat<<EOF
Syntax: $(basename $0) server base binddn password
Re-initialize Samba LDAP config

Arguments:
    server          # LDAP server
    base            # LDAP directory base
    binddn          # LDAP user
    password        # LDAP user password

EOF
    exit 1
}

if [[ "$#" != "4" ]]; then
    usage
fi

LDAP_SERVER=$1
LDAP_BASEDN=$2
LDAP_BINDDN=$3
LDAP_PASS=$4

SAMBA_SID=`net gelocalsid | awk '{print $6}'`

SAMBA_RUNNING=$(/etc/init.d/samba status > /dev/null; echo $?)

# update samba config with ldap parameters
CONF=/etc/samba/smb.conf
sed -i "s|passdb backend.*|passdb backend = ldapsam:$LDAP_SERVER|" $CONF
sed -i "s|ldap suffix.*|ldap suffix = $LDAP_BASEDN|" $CONF
sed -i "s|ldap admin dn.*|ldap admin dn = $LDAP_BINDDN|" $CONF
sed -i "s|idmap backend.*|idmap backend = ldap:$LDAP_SERVER|" $CONF

smbpasswd -w $LDAP_PASS

# update ldapmapuser script with ldap parameters
CONF=/usr/local/bin/ldapmapuser.sh
sed -i "s|ldap:.*|ldap:$LDAP_SERVER -b "$LDAP_BASEDN" \|" $CONF

# restart samba if it was running, or stop it
if [ "$SAMBA_RUNNING" == "0" ]; then
    /etc/init.d/samba restart
else
    /etc/init.d/samba stop
fi

