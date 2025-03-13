#!/bin/bash

apt-get update

apt-get install -y iproute2

mkdir -p /usr/local/etc/haproxy
chmod 755 /usr/local/etc/haproxy

get_public_ips() {
    ip addr | grep 'inet ' | grep -v '127.0.0.1' | \
    grep -v -E '(^|\s)(10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)' | \
    awk '{print $2}' | cut -d'/' -f1
}

generate_server_lines() {
    i=1
    for ip in $(get_public_ips); do
        printf "    server proxy%d amsterdam.mainnet.block-engine.jito.wtf:443 ssl verify none source %s\n" "$i" "$ip"
        i=$((i + 1))
    done
}

mkdir -p /etc/haproxy/certs
cd /etc/haproxy/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout private.key -out certificate.crt \
  -subj "/CN=localhost"

cat certificate.crt private.key > haproxy.pem
chmod 600 haproxy.pem


cat > /usr/local/etc/haproxy/haproxy.cfg << EOF
global
    log stdout format raw  local0 info
    maxconn 50000
    ssl-default-bind-ciphersuites TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11

defaults
    log global
    mode http
    option dontlognull
    option http-keep-alive
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend ft_proxy
    bind *:3000
    bind *:3001 ssl crt /etc/haproxy/certs/haproxy.pem alpn h2,http/1.1
    mode http
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    default_backend bk_proxy

backend bk_proxy
    mode http
    http-request add-header X-Forwarded-Proto https
    balance leastconn
    option tcp-check
    tcp-check connect
    http-request del-header X-Forwarded-For
    http-request del-header X-Real-IP
    http-request del-header Host
    http-request set-header Host amsterdam.mainnet.block-engine.jito.wtf
$(generate_server_lines)
EOF


chown haproxy:haproxy /usr/local/etc/haproxy/haproxy.cfg
chmod 644 /usr/local/etc/haproxy/haproxy.cfg

exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -d
