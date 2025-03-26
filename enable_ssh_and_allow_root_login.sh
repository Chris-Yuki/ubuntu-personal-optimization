#!/bin/bash

# 1. 安装SSH服务（幂等操作）
if ! dpkg -l | grep -q openssh-server; then
  echo "正在安装OpenSSH服务..."
  sudo apt update && sudo apt install -y openssh-server  [[2]][[6]][[10]]
else
  echo "SSH服务已存在，跳过安装。"
fi

# 2. 配置允许Root登录（精确匹配）
if ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
  echo "配置SSH允许Root登录..."
  sudo sed -i '/^#PermitRootLogin prohibit-password$/s/^#//; /^PermitRootLogin/s/prohibit-password/yes/' /etc/ssh/sshd_config  [[7]][[8]]
else
  echo "Root登录已允许，跳过配置。"
fi

# 3. 重启SSH服务（仅在配置变更时重启）
if ! systemctl is-active --quiet ssh; then
  sudo systemctl restart ssh
  echo "SSH服务已重启。"
fi

echo "操作完成。可通过 ssh root@your_ip 登录（需已知Root密码）。"