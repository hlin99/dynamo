#!/bin/bash
# check_and_set_mtu.sh
# 检查 192.168.1.x 网卡 MTU，不是 9000 就设置为 9000

TARGET_MTU=9000

# 找出所有 192.168.1.x 的网卡接口名
INTERFACES=$(ip addr show | grep "192.168.1\." | awk '{print $NF}')

if [ -z "$INTERFACES" ]; then
    echo "未找到 192.168.1.x 网段的网卡"
    exit 1
fi

for iface in $INTERFACES; do
    current_mtu=$(ip link show "$iface" | grep -oP 'mtu \K\d+')
    if [ "$current_mtu" -eq "$TARGET_MTU" ]; then
        echo "[OK]   $iface MTU=$current_mtu，无需修改"
    else
        echo "[FIX]  $iface MTU=$current_mtu → 设置为 $TARGET_MTU"
        ip link set "$iface" mtu $TARGET_MTU
        # 验证是否设置成功
        new_mtu=$(ip link show "$iface" | grep -oP 'mtu \K\d+')
        if [ "$new_mtu" -eq "$TARGET_MTU" ]; then
            echo "[OK]   $iface MTU 已成功设置为 $TARGET_MTU"
        else
            echo "[ERR]  $iface MTU 设置失败，当前仍为 $new_mtu（可能需要 sudo）"
        fi
    fi
done
