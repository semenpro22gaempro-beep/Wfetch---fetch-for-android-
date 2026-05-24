#!/usr/bin/env bash

# Цвета
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_RESET='\033[0m'

# Сбор информации
OS=$(grep -oP '^PRETTY_NAME="\K[^\"]+' /etc/os-release 2>/dev/null || echo "Linux")
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')
SHELL_NAME=$(basename "$SHELL")
PACKAGES=$(dpkg --list | grep -c "^ii" 2>/dev/null || pacman -Qq | wc -l 2>/dev/null || echo "N/A")
CPU=$(lscpu | grep -m 1 "Model name" | sed -e 's/.*: *//' -e 's/(R)//g' -e 's/(TM)//g' | cut -c1-25)
MEMORY=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}' || echo "N/A")

# Вывод ASCII-арта и информации (7 строк)
echo -e "   ${C_CYAN}__${C_RESET}       ${C_BLUE}OS:${C_RESET}     $OS"
echo -e "  ${C_CYAN}(_ \\${C_RESET}      ${C_BLUE}Kernel:${C_RESET} $KERNEL"
echo -e "  ${C_CYAN}/  /_${C_RESET}     ${C_BLUE}Uptime:${C_RESET} $UPTIME"
echo -e " ${C_CYAN}/ ___/\\\\${C_RESET}    ${C_BLUE}Shell:${C_RESET}  $SHELL_NAME"
echo -e "${C_CYAN}(__(_)_) ${C_RESET}   ${C_BLUE}Pkgs:${C_RESET}   $PACKAGES"
echo -e "            ${C_BLUE}CPU:${C_RESET}    $CPU..."
echo -e "            ${C_BLUE}RAM:${C_RESET}    $MEMORY"