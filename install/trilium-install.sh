#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TriliumNext/Trilium

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-$(arch_resolve "x64" "arm64").tar.xz" "v"

    msg_info "Creating Service"
    cat <<EOF >/etc/systemd/system/trilium.service
[Unit]
Description=Trilium Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=/opt/trilium/trilium.sh
WorkingDirectory=/opt/trilium/
TimeoutStopSec=20
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now -q trilium
    msg_ok "Created Service"
}

setup_alpine() {
    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-$(arch_resolve "x64" "arm64").tar.xz" "v"

    msg_info "Creating Service"
    cat <<EOF >/etc/init.d/trilium
#!/sbin/openrc-run
name="trilium"
description="Trilium Daemon"
command="/opt/trilium/trilium.sh"
command_background="yes"
pidfile="/run/trilium.pid"

depend() {
    need net
    after logger
}
EOF
    chmod +x /etc/init.d/trilium
    rc-update add trilium default
    rc-service trilium start
    msg_ok "Created Service"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
