#!/bin/bash

apt-get update

apt-get install -y iproute2

mkdir -p /usr/local/etc/haproxy
chmod 755 /usr/local/etc/haproxy

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
    nbthread 8

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option http-server-close
    option forwardfor
    log-format "%ci:%cp [%tr] %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq %hr %hs %{+Q}r %Tt"
    timeout connect 3s
    timeout client 30s
    timeout server 30s

frontend ft_jito
    bind *:30000
    mode http
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    log global
    
    use_backend bk_jito_3000 if { dst_port 30000 }

backend bk_jito_3000
    mode http
    balance roundrobin
    option tcp-check
    tcp-check connect
    
    server ams1 127.0.0.1:3000 weight 16 check

EOF


chown haproxy:haproxy /usr/local/etc/haproxy/haproxy.cfg
chmod 644 /usr/local/etc/haproxy/haproxy.cfg

exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -W
