#!/usr/bin/env bash
set -euo pipefail

CODE_SERVER_PASSWORD="ChangeMe_123456"
CODE_SERVER_PORT="8080"

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
apt-get install -y software-properties-common apt-transport-https ca-certificates gnupg curl wget git jq ufw htop

add-apt-repository universe -y
add-apt-repository ppa:zhangsongcui3371/fastfetch -y
apt-get update
apt-get install -y fastfetch build-essential make zlib1g-dev libssl-dev libffi-dev libpq-dev

apt-get install -y python3 python3-pip python3-venv python3-dev pipx
pipx ensurepath

mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
npm install -g pnpm yarn

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

curl -fsSL https://code-server.dev/install.sh | sh

mkdir -p /root/.config/code-server
cat <<EOF > /root/.config/code-server/config.yaml
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
EOF

cat <<EOF > /etc/systemd/system/code-server.service
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/code-server --config /root/.config/code-server/config.yaml /root
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now code-server.service

code-server --install-extension kilocode.kilo-code || true

ufw allow OpenSSH
ufw allow ${CODE_SERVER_PORT}/tcp
ufw --force enable

echo "SETUP_SUCCESS"
