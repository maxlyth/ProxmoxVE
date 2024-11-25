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
$STD apt-get install -y {curl,jq}
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
mkdir -p /storage

msg_info "Creating Services"
mkdir -p /etc/systemd/system
cat <<EOF >/etc/systemd/system/victoriametrics.service
[Unit]
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/storage
ExecStart=/opt/victoria-metrics-prod --storageDataPath=/storage --retentionPeriod=12 --httpListenAddr=:8428 --graphiteListenAddr=:2003 --opentsdbListenAddr=:4242 --influxListenAddr=:8089
SyslogIdentifier=victoriametrics

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now victoriametrics
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
rm -rf /opt/victoria-metrics-linux-amd64-$RELEASE.*
rm -rf /opt/vmutils-linux-amd64-$RELEASE.*
$STD apt-get -y autoclean
msg_ok "Cleaned"
