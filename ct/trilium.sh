#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TriliumNext/Trilium

APP="Trilium"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine 3.24 (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-2}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /opt/trilium ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Trilium" "TriliumNext/Trilium" "" "" "v"; then
    if [[ -d /opt/trilium/db ]]; then
      DB_PATH="/opt/trilium/db"
      DB_RESTORE_PATH="/opt/trilium/db"
    elif [[ -d /opt/trilium/assets/db ]]; then
      DB_PATH="/opt/trilium/assets/db"
      DB_RESTORE_PATH="/opt/trilium/assets/db"
    else
      msg_error "Database not found in either /opt/trilium/db or /opt/trilium/assets/db"
      exit
    fi

    msg_info "Stopping Service"
    systemctl stop trilium
    sleep 1
    msg_ok "Stopped Service"

    msg_info "Backing up Database"
    mkdir -p /opt/trilium_backup
    cp -r "${DB_PATH}" /opt/trilium_backup/
    rm -rf /opt/trilium
    msg_ok "Backed up Database"

    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-$(arch_resolve "x64" "arm64").tar.xz" "v"

    msg_info "Restoring Database"
    mkdir -p "$(dirname "${DB_RESTORE_PATH}")"
    cp -r /opt/trilium_backup/$(basename "${DB_PATH}") "${DB_RESTORE_PATH}"
    rm -rf /opt/trilium_backup
    msg_ok "Restored Database"

    msg_info "Starting Service"
    systemctl start trilium
    sleep 1
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

update_alpine() {
  if [[ ! -d /opt/trilium ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Trilium" "TriliumNext/Trilium" "" "" "v"; then
    if [[ -d /opt/trilium/db ]]; then
      DB_PATH="/opt/trilium/db"
      DB_RESTORE_PATH="/opt/trilium/db"
    elif [[ -d /opt/trilium/assets/db ]]; then
      DB_PATH="/opt/trilium/assets/db"
      DB_RESTORE_PATH="/opt/trilium/assets/db"
    else
      msg_error "Database not found in either /opt/trilium/db or /opt/trilium/assets/db"
      exit
    fi

    msg_info "Stopping Service"
    rc-service trilium stop
    sleep 1
    msg_ok "Stopped Service"

    msg_info "Backing up Database"
    mkdir -p /opt/trilium_backup
    cp -r "${DB_PATH}" /opt/trilium_backup/
    rm -rf /opt/trilium
    msg_ok "Backed up Database"

    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-$(arch_resolve "x64" "arm64").tar.xz" "v"

    msg_info "Restoring Database"
    mkdir -p "$(dirname "${DB_RESTORE_PATH}")"
    cp -r /opt/trilium_backup/$(basename "${DB_PATH}") "${DB_RESTORE_PATH}"
    rm -rf /opt/trilium_backup
    msg_ok "Restored Database"

    msg_info "Starting Service"
    rc-service trilium start
    sleep 1
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
