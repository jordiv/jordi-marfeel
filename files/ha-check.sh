#!/bin/bash

IPLIST='/etc/haproxy/ips.txt'
HAPROXY_CONF='/etc/haproxy/haproxy.cfg'
HAPROXY_NEW='/etc/haproxy/haproxy.cfg.new'

# Ensure ip list file exists
touch "${IPLIST}"

# Get IPs from AWS to txt file and check if there's any change
IPLIST_MD5_ACTUAL=$(md5sum ${IPLIST} | awk '{ print $1 }')
aws ec2 describe-instances --filter Name=tag-key,Values=Environment,running | grep \"PrivateIpAddress\" | awk -F '"' '{ print $4 }' | uniq > "${IPLIST}"
IPLIST_MD5_NEW=$(md5sum ${IPLIST} | awk '{ print $1 }')
[[ "${IPLIST_MD5_ACTUAL}" = "${IPLIST_MD5_NEW}" ]] && echo "No changes; no reload needed." && exit

# Create template
cat > "${HAPROXY_NEW}" <<'EOF'
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL). This list is from:
        #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
        ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
        ssl-default-bind-options no-sslv3

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend test_frontend 
  mode http
  maxconn 2000
  bind *:80 name http
  default_backend test_backend

backend test_backend 
  mode http
  balance roundrobin
EOF

# Loop for each ip and add server line into config
SERVER_COUNT=1
while read -r IP; do
	echo "  server server${SERVER_COUNT} ${IP}:80 check maxconn 30 weight 100" >> "${HAPROXY_NEW}"
	let SERVER_COUNT=SERVER_COUNT+1
done < "${IPLIST}"

# Check consistency and reload haproxy service
/usr/sbin/haproxy -f "${HAPROXY_NEW}" -c && mv "${HAPROXY_NEW}" "${HAPROXY_CONF}" && systemctl reload haproxy
