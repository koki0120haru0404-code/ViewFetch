#!/bin/sh

# OS判定
OS=$(uname)

if ((BASH_VERSINFO[0] < 1)); then
    printf "\033[31mエラー: このアプリは Bash 1.0 以上が必要です。\033[0m\n"""
    exit 1
fi
if ((BASH_VERSINFO[0] < 2)); then
    #echo "警告: このアプリは Bash 2.0 以上が推奨です。(Bash 1.0でも動作可能)"
    printf "\033[33m警告: このアプリは Bash 2.0 以上が推奨です。(Bash 1.0でも動作可能)\033[0m\n"""
fi

if [ "$OS" = "Linux" ]; then
    # --- Linux ---
    OSicon=🐧

    CPU=$(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' | sed 's/  */ /g')
    [ -z "$CPU" ] && CPU=$(uname -m)

    RAM=$(free -h | awk '/^Mem:/ {print $2}')

    if command -v xrandr >/dev/null 2>&1; then
        DYSPLAY=$(xrandr | grep '*' | awk 'NR==1 {print $1}')
    else
        DYSPLAY=$(xdpyinfo | grep dimensions | awk '{print $2}' 2>/dev/null)
    fi
    [ -z "$DYSPLAY" ] && DYSPLAY="Unknown"

    if command -v nvidia-smi >/dev/null 2>&1; then
        GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n 1)
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1 | awk '{print $1 "MB"}')
    else
        GPU=$(lspci 2>/dev/null | grep -i -E 'vga|3d' | cut -d: -f3 | sed 's/^[ \t]*//' | head -n 1)
        [ -z "$GPU" ] && GPU="Internal_GPU"
        VRAM="Unknown"
    fi

    DISK=$(df -h / | awk 'NR==2 {print $2}')
    
    ROOT_DEV=$(lsblk -no pkname $(df / | awk 'NR==2 {print $1}') 2>/dev/null | head -n 1)
    [ -z "$ROOT_DEV" ] && ROOT_DEV="sda"
    ROT=$(cat /sys/block/${ROOT_DEV}/queue/rotational 2>/dev/null)
    if [ "$ROT" = "0" ]; then
        DISKR="SSD"
    elif [ "$ROT" = "1" ]; then
        DISKR="HDD"
    else
        DISKR="Unknown"
    fi

elif [ "$OS" = "Darwin" ]; then
    # --- macOS ---
    OSicon=🍎

    CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model)
    
    RAM=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 "GB"}')
    
    DYSPLAY=$(system_profiler SPDisplaysDataType 2>/dev/null | grep Resolution | awk 'NR==1 {print $2 "x" $4}')
    [ -z "$DYSPLAY" ] && DYSPLAY="Unknown"
    
    GPU=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | cut -d: -f2 | sed 's/^[ \t]*//' | head -n 1)
    
    VRAM_RAW=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "VRAM" | cut -d: -f2 | sed 's/^[ \t]*//' | head -n 1)
    if [ -n "$VRAM_RAW" ]; then
        VRAM=$VRAM_RAW
    else
        VRAM="UnifiedMemory"
    fi
    
    DISK=$(df -h / | awk 'NR==2 {print $2}')
    
    DISKR=$(system_profiler SPStorageDataType 2>/dev/null | grep "Medium Type" | head -n 1 | cut -d: -f2 | sed 's/^[ \t]*//')
    [ -z "$DISKR" ] && DISKR="SSD" # Apple Silicon等はSSD固定
else
    echo "Unsupported OS"
    exit 1
fi

printf "\033[1;36mCPU\033[0m:%s\n" "${CPU}"
printf "\033[1;36mGPU\033[0m:%s\n" "${GPU}"
printf "\033[1;36mRAM\033[0m:%s\n" "${RAM}"
printf "\033[1;36mResolution\033[0m:%s\n" "${DYSPLAY}"
printf "\033[1;36mVRAM\033[0m:%s\n" "${VRAM}"
printf "\033[1;36mCapacity\033[0m:%s\n" "${DISK}"
printf "\033[1;36mDISK\033[0m:%s\n" "${DISKR}"
printf "\033[1;36mOS\033[0m:%s\n" "${OS} ${OSicon}"