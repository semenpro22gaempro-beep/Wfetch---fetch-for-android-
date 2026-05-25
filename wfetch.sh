#!/usr/bin/env bash

# Цвета (ANSI)
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_MAGENTA='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_RESET='\033[0m'

# 1. Определение операционной системы
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    SYS_TYPE="windows"
elif [ -f /etc/os-release ]; then
    ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$ID" in
        ubuntu) SYS_TYPE="ubuntu" ;;
        debian) SYS_TYPE="debian" ;;
        arch)   SYS_TYPE="arch"   ;;
        *)      SYS_TYPE="unknown" ;;
    esac
else
    SYS_TYPE="unknown"
fi

# 2. Сбор расширенной информации
USER_HOST="${USER:-user}@${HOSTNAME:-pc}"

if [ "$SYS_TYPE" = "windows" ]; then
    OS_NAME=$(wmic os get Caption | sed -n '2p' | tr -d '\r' | xargs)
    KERNEL=$(wmic os get Version | sed -n '2p' | tr -d '\r' | xargs)
    UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo "0")
    SHELL_VER=$("$SHELL" --version | head -n1 | cut -d' ' -f4)
    PACKAGES="N/A (Windows)"
    CPU=$(wmic cpu get Name | sed -n '2p' | sed -e 's/(R)//g' -e 's/(TM)//g' | cut -c1-30 | tr -d '\r' | xargs)
    
    # Память Windows
    MEM_TOTAL=$(wmic computersystem get TotalPhysicalMemory | sed -n '2p' | tr -d '\r' | xargs)
    MEM_FREE=$(wmic os get FreePhysicalMemory | sed -n '2p' | tr -d '\r' | xargs)
    if [ -n "$MEM_TOTAL" ] && [ -n "$MEM_FREE" ]; then
        MEM_T_GB=$((MEM_TOTAL / 1024 / 1024 / 1024))
        MEM_F_GB=$((MEM_FREE / 1024 / 1024))
        MEM_U_GB=$((MEM_T_GB - MEM_F_GB))
        MEMORY="${MEM_U_GB}GB / ${MEM_T_GB}GB"
    else
        MEMORY="N/A"
    fi
    # Разрешение экрана
    RES=$(wmic path Win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution | sed -n '2p' | awk '{print $1"x"$2}' | tr -d '\r')
else
    # Сбор данных для Linux / WSL
    OS_NAME=$(grep -oP '^PRETTY_NAME="\K[^\"]+' /etc/os-release 2>/dev/null || echo "Linux")
    KERNEL=$(uname -r)
    UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo "0")
    SHELL_VER=$("$SHELL" --version | head -n1 | awk '{print $4}' 2>/dev/null || echo "v$BASH_VERSION")
    PACKAGES=$(dpkg --list | grep -c "^ii" 2>/dev/null || pacman -Qq | wc -l 2>/dev/null || echo "Unknown")
    CPU=$(lscpu | grep -m 1 "Model name" | sed -e 's/.*: *//' -e 's/(R)//g' -e 's/(TM)//g' | cut -c1-30 | xargs)
    MEMORY=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}' || echo "N/A")
    RES=$(xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}' || echo "N/A (CLI)")
fi

# Форматирование аптайма
if [ "$UPTIME_SEC" -gt 0 ]; then
    UPTIME=$(printf "%dh %dm %ds" $((UPTIME_SEC/3600)) $((UPTIME_SEC%3600/60)) $((UPTIME_SEC%60)))
else
    UPTIME="N/A"
fi

# Диск (корень)
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# Разделитель под именем пользователя
LINE=$(echo "$USER_HOST" | sed 's/./-/g')

# 3. Вывод в зависимости от системы
case "$SYS_TYPE" in
    windows)
        echo -e "${C_CYAN}    #################${C_RESET}   ${C_GREEN}${USER_HOST}${C_RESET}"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_WHITE}${LINE}${C_RESET}"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}OS:${C_RESET}       $OS_NAME"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}Kernel:${C_RESET}   $KERNEL"
        echo -e "${C_CYAN}    #################${C_RESET}   ${C_YELLOW}Uptime:${C_RESET}   $UPTIME"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}Shell:${C_RESET}    $(basename "$SHELL") $SHELL_VER"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}Packages:${C_RESET} $PACKAGES"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}Display:${C_RESET}  $RES"
        echo -e "${C_CYAN}    ####      #######${C_RESET}   ${C_YELLOW}CPU:${C_RESET}      $CPU"
        echo -e "                        ${C_YELLOW}RAM:${C_RESET}      $MEMORY"
        echo -e "                        ${C_YELLOW}Disk (/):${C_RESET} $DISK"
        ;;
    ubuntu)
        echo -e "${C_RED}         _nnnn_${C_RESET}         ${C_GREEN}${USER_HOST}${C_RESET}"
        echo -e "${C_RED}        /      \\\\${C_RESET}        ${C_WHITE}${LINE}${C_RESET}"
        echo -e "${C_RED}       |  O  O  |${C_RESET}       ${C_YELLOW}OS:${C_RESET}       $OS_NAME"
        echo -e "${C_RED}       |   __   |${C_RESET}       ${C_YELLOW}Kernel:${C_RESET}   $KERNEL"
        echo -e "${C_RED}      /|  \\__/  |\\\\${C_RESET}      ${C_YELLOW}Uptime:${C_RESET}   $UPTIME"
        echo -e "${C_RED}     / |        | \\\\${C_RESET}     ${C_YELLOW}Shell:${C_RESET}    $(basename "$SHELL") $SHELL_VER"
        echo -e "${C_RED}    /  |________|  \\\\${C_RESET}    ${C_YELLOW}Packages:${C_RESET} $PACKAGES"
        echo -e "${C_RED}    \`__\\        /__\`${C_RESET}    ${C_YELLOW}Display:${C_RESET}  $RES"
        echo -e "${C_RED}        |      |${C_RESET}        ${C_YELLOW}CPU:${C_RESET}      $CPU"
        echo -e "${C_RED}        |______|${C_RESET}        ${C_YELLOW}RAM:${C_RESET}      $MEMORY"
        echo -e "                        ${C_YELLOW}Disk (/):${C_RESET} $DISK"
        ;;
    debian)
        echo -e "${C_MAGENTA}       _____${C_RESET}            ${C_GREEN}${USER_HOST}${C_RESET}"
        echo -e "${C_MAGENTA}      /  __ \\\\${C_RESET}           ${C_WHITE}${LINE}${C_RESET}"
        echo -e "${C_MAGENTA}     /  /  \\|${C_RESET}           ${C_YELLOW}OS:${C_RESET}       $OS_NAME"
        echo -e "${C_MAGENTA}     |  |${C_RESET}               ${C_YELLOW}Kernel:${C_RESET}   $KERNEL"
        echo -e "${C_MAGENTA}     \\  \\ ${C_RED}__${C_RESET}           ${C_YELLOW}Uptime:${C_RESET}   $UPTIME"
        echo -e "${C_MAGENTA}      \\  \\${C_RED}/  \\\\${C_RESET}          ${C_YELLOW}Shell:${C_RESET}    $(basename "$SHELL") $SHELL_VER"
        echo -e "${C_MAGENTA}       \\______/${C_RESET}         ${C_YELLOW}Packages:${C_RESET} $PACKAGES"
        echo -e "                        ${C_YELLOW}Display:${C_RESET}  $RES"
        echo -e "                        ${C_YELLOW}CPU:${C_RESET}      $CPU"
        echo -e "                        ${C_YELLOW}RAM:${C_RESET}      $MEMORY"
        echo -e "                        ${C_YELLOW}Disk (/):${C_RESET} $DISK"
        ;;
    arch)
        echo -e "${C_CYAN}          /\\\\${C_RESET}            ${C_GREEN}${USER_HOST}${C_RESET}"
        echo -e "${C_CYAN}         /  \\\\${C_RESET}           ${C_WHITE}${LINE}${C_RESET}"
        echo -e "${C_CYAN}        /\`    \\\\${C_RESET}          ${C_YELLOW}OS:${C_RESET}       $OS_NAME"
        echo -e "${C_CYAN}       /      \\\\${C_RESET}         ${C_YELLOW}Kernel:${C_RESET}   $KERNEL"
        echo -e "${C_CYAN}      /  (    ) \\\\${C_RESET}        ${C_YELLOW}Uptime:${C_RESET}   $UPTIME"
        echo -e "${C_CYAN}     /  \_ /\\\\ _/  \\\\${C_RESET}       ${C_YELLOW}Shell:${C_RESET}    $(basename "$SHELL") $SHELL_VER"
        echo -e "${C_CYAN}    /___ _     _ ___\\\\${C_RESET}      ${C_YELLOW}Packages:${C_RESET} $PACKAGES"
        echo -e "                        ${C_YELLOW}Display:${C_RESET}  $RES"
        echo -e "                        ${C_YELLOW}CPU:${C_RESET}      $CPU"
        echo -e "                        ${C_YELLOW}RAM:${C_RESET}      $MEMORY"
        echo -e "                        ${C_YELLOW}Disk (/):${C_RESET} $DISK"
        ;;
    *)
        # Дефолтный большой TUX (Неизвестная ОС)
        echo -e "     ${C_WHITE}    .---.${C_RESET}          ${C_GREEN}${USER_HOST}${C_RESET}"
        echo -e "     ${C_WHITE}   /     \\${C_RESET}         ${C_WHITE}${LINE}${C_RESET}"
        echo -e "     ${C_WHITE}   \\_.._/${C_RESET}         ${C_YELLOW}OS:${C_RESET}       $OS_NAME"
        echo -e "     ${C_WHITE}   | ()() |${C_RESET}        ${C_YELLOW}Kernel:${C_RESET}   $KERNEL"
        echo -e "     ${C_WHITE}    \\  ==  /${C_RESET}        ${C_YELLOW}Uptime:${C_RESET}   $UPTIME"
        echo -e "     ${C_WHITE}   .-\`''\`-.${C_RESET}        ${C_YELLOW}Shell:${C_RESET}    $(basename "$SHELL") $SHELL_VER"
        echo -e "     ${C_WHITE}  /  ..    \\${C_RESET}       ${C_YELLOW}Packages:${C_RESET} $PACKAGES"
        echo -e "     ${C_WHITE}  | |  |    |${C_RESET}      ${C_YELLOW}Display:${C_RESET}  $RES"
        echo -e "     ${C_WHITE}   \\ \\_|_/ /${C_RESET}       ${C_YELLOW}CPU:${C_RESET}      $CPU"
        echo -e "     ${C_WHITE}   /       \\${C_RESET}       ${C_YELLOW}RAM:${C_RESET}      $MEMORY"
        echo -e "     ${C_WHITE}   \\_______/${C_RESET}       ${C_YELLOW}Disk (/):${C_RESET} $DISK"
        ;;
esac
echo -e "\n"
