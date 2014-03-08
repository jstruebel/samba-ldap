#!/bin/sh
ldapsearch -x -LLL -h ldap://127.0.0.1 -b "dc=example,dc=com" \
  -s sub "(&(cn=$1)(objectclass=posixAccount))" | grep uid: | \
  cut -d: -f 2 | sed 's/^\s*//'
