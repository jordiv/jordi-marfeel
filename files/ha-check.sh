#!/bin/bash

IPLIST='/etc/haproxy/ips.txt'
HAPROXY_CONF='/etc/haproxy/haproxy.cfg'
HAPROXY_BAK='/etc/haproxy/haproxy.cfg.bak'

# Backup config just in case and ensure ip list file exists
cp "${HAPROXY_CONF}" "${HAPROXY_BAK}"
touch "${IPLIST}"

# Get IPs from AWS to txt file and check if there's any change
IPLIST_MD5_ACTUAL=$(md5sum ${IPLIST} | awk '{ print $1 }')
aws ec2 describe-instances --filter Name=tag-key,Values=Environment,running | grep \"PrivateIpAddress\" | awk -F '"' '{ print $4 }' | uniq > "${IPLIST}"
IPLIST_MD5_NEW=$(md5sum ${IPLIST} | awk '{ print $1 }')
[[ "${IPLIST_MD5_ACTUAL}" = "${IPLIST_MD5_NEW}" ]] && echo "No changes; no reload needed." && exit

# Delete server lines in backend (assuming they are at the end of the file)
while $(tail -n1 "${HAPROXY_CONF}" | egrep -q '^  server') || $(tail -n1 "${HAPROXY_CONF}" | egrep -q '^$'); do
	sed '$ d' -i "${HAPROXY_CONF}"
done

# Loop for each ip and add server line into config
SERVER_COUNT=1
while read -r IP; do
	echo "  server server${SERVER_COUNT} ${IP}:80 check maxconn 30 weight 100" >> "${HAPROXY_CONF}"
	let SERVER_COUNT=SERVER_COUNT+1
done < "${IPLIST}"

# Check consistency and reload haproxy service
haproxy -f "${HAPROXY_CONF}" -c && service haproxy reload || mv "${HAPROXY_BAK}" "${HAPROXY_CONF}"
