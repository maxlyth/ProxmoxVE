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
SVC="victoriametrics"
var_disk="24"
var_cpu="1"
var_ram="1024"
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
  if [[ ! -f /etc/systemd/system/${SVC}.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_error "To update ${APP}, create a new container and transfer your data."
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "Configuration files are located in ${YWB}/etc/victoriametrics/${CL}. \n"
echo -e "${APP} web UI should be reachable by going to the following URL.
         ${BL}http://${IP}:8428/vmui${CL} \n"
