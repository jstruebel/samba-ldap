#!/bin/bash -e

fatal() {
    echo "fatal: $@" 1>&2
    exit 1
}

usage() {
cat<<EOF
Syntax: $(basename $0) server base binddn password firstboot
Re-initialize Samba LDAP config

Arguments:
    server          # LDAP server
    base            # LDAP directory base
    binddn          # LDAP user
    password        # LDAP user password
    firstboot       # Indicates first boot with default params

EOF
    exit 1
}

if [[ "$#" != "5" ]]; then
    usage
fi

LDAP_SERVER=$1
LDAP_BASEDN=$2
LDAP_BINDDN=$3
LDAP_PASS=$4
SAMBA_FIRSTBOOT=$5

# update samba config with ldap parameters
CONF=/etc/samba/smb.conf
sed -i "s|passdb backend.*|passdb backend = ldapsam:ldap://$LDAP_SERVER|" $CONF
sed -i "s|ldap suffix.*|ldap suffix = $LDAP_BASEDN|" $CONF
sed -i "s|ldap admin dn.*|ldap admin dn = $LDAP_BINDDN|" $CONF
sed -i "s|idmap backend.*|idmap backend = ldap:ldap://$LDAP_SERVER|" $CONF

smbpasswd -w $LDAP_PASS

# run net getlocalsid to populate sambaDomainName info in LDAP
net getlocalsid > /dev/null

# update ldapmapuser script with ldap parameters
CONF=/usr/local/bin/ldapmapuser.sh
sed -i "s|ldap:.*|ldap://$LDAP_SERVER -b \"$LDAP_BASEDN\" \\\\|" $CONF

# start samba and enable on system startup after configured
if [ "$SAMBA_FIRSTBOOT" == "0" ]; then
    if [ -f /bin/systemctl ]; then
        systemctl enable samba.service
    else
        update-rc.d samba defaults
    fi
    /etc/init.d/samba start
fi

