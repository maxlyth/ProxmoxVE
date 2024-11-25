#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: maxlyth
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y {curl,sudo,mc,jq}
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | jq -r '.tag_name')
msg_info "Installing VictoriaMetrics $RELEASE"
cd /opt
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$RELEASE/victoria-metrics-linux-amd64-$RELEASE.tar.gz
gunzip -q victoria-metrics-linux-amd64-$RELEASE.tar.gz
tar -xf victoria-metrics-linux-amd64-$RELEASE.tar
chmod +x victoria-metrics-prod
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$RELEASE/vmutils-linux-amd64-$RELEASE.tar.gz
gunzip -q vmutils-linux-amd64-$RELEASE.tar.gz
tar -xf vmutils-linux-amd64-$RELEASE.tar
chmod +x vm*-prod
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed VictoriaMetrics"

msg_info "Creating Config"
mkdir -p /etc/victoriametrics
mkdir -p /var/lib/victoria-metrics-data
cat <<EOF >/etc/victoriametrics/scrape.yml
# Scrape config example
#
scrape_configs:
  - job_name: self_scrape
    scrape_interval: 10s
    static_configs:
      - targets: ['127.0.0.1:8428']
EOF
cat <<EOF >/etc/victoriametrics/victoriametrics.conf
ARGS="-promscrape.config=/etc/victoriametrics/scrape.yml -storageDataPath=/var/lib/victoria-metrics-data -retentionPeriod=12 -httpListenAddr=:8428 -graphiteListenAddr=:2003 -opentsdbListenAddr=:4242 -influxListenAddr=:8089 -enableTCP6"
EOF

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/victoriametrics.service
[Unit]
Description=VictoriaMetrics is a fast, cost-effective and scalable monitoring solution and time series database.
# https://docs.victoriametrics.com
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/lib/victoria-metrics-data
StartLimitBurst=5
StartLimitInterval=0
Restart=on-failure
RestartSec=5
EnvironmentFile=-/etc/victoriametrics/victoriametrics.conf
ExecStart=/opt/victoria-metrics-prod $ARGS
ExecStop=/bin/kill -s SIGTERM $MAINPID
ExecReload=/bin/kill -HUP $MAINPID
# See docs https://docs.victoriametrics.com/single-server-victoriametrics/#tuning
ProtectSystem=full
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=victoriametrics

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now victoriametrics
sleep 3
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
rm -rf /opt/victoria-metrics-linux-amd64-$RELEASE.*
rm -rf /opt/vmutils-linux-amd64-$RELEASE.*
$STD apt-get -y autoclean
msg_ok "Cleaned"
