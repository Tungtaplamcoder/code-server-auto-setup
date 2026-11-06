#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------
# 0. CẤU HÌNH MẬT KHẨU CODE-SERVER
# -------------------------------------------------------------
CODE_SERVER_PASSWORD="ChangeMe_123456" # Đổi mật khẩu này trước khi chạy!
CODE_SERVER_PORT="8080"

echo "=== [1/6] CẬP NHẬT HỆ THỐNG & CÀI TIỆN ÍCH CƠ BẢN ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
apt-get install -y \
    curl wget git jq ufw htop fastfetch \
    software-properties-common apt-transport-https ca-certificates gnupg \
    build-essential make zlib1g-dev libssl-dev libffi-dev libpq-dev

echo "=== [2/6] CÀI ĐẶT PYTHON 3 & CÔNG CỤ BUILD ==="
apt-get install -y python3 python3-pip python3-venv python3-dev pipx
pipx ensurepath

echo "=== [3/6] CÀI ĐẶT NODE.JS (LTS) & PACKAGE MANAGERS ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
npm install -g pnpm yarn

echo "=== [4/6] CÀI ĐẶT DOCKER ENGINE & DOCKER COMPOSE ==="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

echo "=== [5/6] CÀI ĐẶT CODE-SERVER & TIỆN ÍCH EXTENSION ==="
# Cài đặt code-server bản chính thức
curl -fsSL https://code-server.dev/install.sh | sh

# Tạo thư mục cấu hình cho root
mkdir -p /root/.config/code-server
cat <<EOF > /root/.config/code-server/config.yaml
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
EOF

# Kích hoạt và chạy service cho user root
systemctl enable --now code-server@root

# Cài extension Kilo Code vào code-server (qua Open-VSX)
echo "Đang cài đặt extension Kilo Code..."
code-server --install-extension kilocode.kilo-code || echo "Cảnh báo: Hãy cài extension Kilo Code thủ công trên giao diện nếu mạng timeout."

echo "=== [6/6] CẤU HÌNH TƯỜNG LỬA (UFW) ==="
ufw allow OpenSSH
ufw allow ${CODE_SERVER_PORT}/tcp
ufw --force enable

echo "=========================================================="
echo "                   SETUP HOÀN TẤT!                        "
echo "=========================================================="
echo "1. Code Server Web UI: http://<IP_VPS>:${CODE_SERVER_PORT}"
echo "   Password: ${CODE_SERVER_PASSWORD}"
echo "2. VS Code Remote SSH: Đã sẵn sàng (SSH trực tiếp bằng root qua port 22)."
echo "3. Kiểm tra thông số máy: Gõ lệnh 'fastfetch' hoặc 'htop'"
echo "4. Docker: Gõ 'docker compose version' để kiểm tra."
echo "=========================================================="
