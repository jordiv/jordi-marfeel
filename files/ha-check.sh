#!/bin/bash

IPLIST='/etc/haproxy/ips.txt'
HAPROXY_CONF='/etc/haproxy/haproxy.cfg'

# Get IPs from AWS to txt file and check if there's any change
IPLIST_MD5_ACTUAL=$(md5sum ${IPLIST} | awk '{ print $1 }')
aws ec2 describe-instances --filter Name=tag-key,Values=Environment,running | grep \"PrivateIpAddress\" | awk -F '"' '{ print $4 }' | uniq > "${IPLIST}"
IPLIST_MD5_NEW=$(md5sum ${IPLIST} | awk '{ print $1 }')
[[ "${IPLIST_MD5_ACTUAL}" = "${IPLIST_MD5_NEW}" ]] && echo "No changes; no reload needed." && exit

# Get IPs from file and set into two variables
{ IFS= read -r IP1 && IFS= read -r IP2; } < "${IPLIST}"

# Change backends server1 and server2 with new IPs
sed -e "s/server1 .*\:80/server1 ${IP1}\:80/" -e "s/server2 .*\:80/server2 ${IP2}\:80/" -i "${HAPROXY_CONF}"

# Check consistency and reload haproxy service
haproxy -f "${HAPROXY_CONF}" -c && systemctl reload haproxy


