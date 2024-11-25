#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/maxlyth/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# bash -c "$(wget -qLO - https://github.com/maxlyth/ProxmoxVE/raw/main/ct/victoriametrics.sh)"

function header_info {
clear
cat <<"EOF"
 _    ___      __             _       __  ___     __       _
| |  / (_)____/ /_____  _____(_)___ _/  |/  /__  / /______(_)_________
| | / / / ___/ __/ __ \/ ___/ / __ `/ /|_/ / _ \/ __/ ___/ / ___/ ___/
| |/ / / /__/ /_/ /_/ / /  / / /_/ / /  / /  __/ /_/ /  / / /__(__  )
|___/_/\___/\__/\____/_/  /_/\__,_/_/  /_/\___/\__/_/  /_/\___/____/

EOF
}
header_info
echo -e "Loading..."
APP="VictoriaMetrics"
var_disk="16"
var_cpu="1"
var_ram="768"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/victoriametrics.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

  RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | jq -r '.tag_name')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$RELEASE/victoria-metrics-linux-amd64-$RELEASE.tar.gz
    gunzip -q victoria-metrics-linux-amd64-$RELEASE.tar.gz
    tar -xf victoria-metrics-linux-amd64-$RELEASE.tar
    chmod +x victoria-metrics-prod
    wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$RELEASE/vmutils-linux-amd64-$RELEASE.tar.gz
    gunzip -q vmutils-linux-amd64-$RELEASE.tar.gz
    tar -xf vmutils-linux-amd64-$RELEASE.tar
    chmod +x vm*-prod
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "Data files are located in ${YWB}/storage/${CL}. \n"
echo -e "${APP} web UI should be reachable by going to the following URL.
         ${BL}http://${IP}:8428/vmui${CL} \n"
