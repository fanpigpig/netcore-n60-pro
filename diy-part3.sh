#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# Remove print samba4
sed -i '/printer/d' target/linux/mediatek/image/mt7986.mk
sed -i 's/kmod-usb-net-rndis //g' target/linux/mediatek/image/mt7986.mk
sed -i 's/ luci-app-samba4//g' target/linux/mediatek/image/mt7986.mk
sed -i '/luci-app-filetransfer/d' include/target.mk

# 添加组播防火墙规则
cat >> package/network/config/firewall/files/firewall.config <<EOF
config rule
        option name 'Allow-UDP-igmpproxy'
        option src 'wan'
        option dest 'lan'
        option dest_ip '224.0.0.0/4'
        option proto 'udp'
        option target 'ACCEPT'        
        option family 'ipv4'

config rule
        option name 'Allow-UDP-udpxy'
        option src 'wan'
        option dest_ip '224.0.0.0/4'
        option proto 'udp'
        option target 'ACCEPT'
EOF
# 修复 mosdns/v2dat 构建失败：上游 feed 补丁把 go.mod 的 go 版本要求写成 1.25.0，
# 而构建树的 Go 工具链拒绝解析（invalid go version '1.25.0': must match format 1.23）；
# 相关代码兼容 go 1.23，把补丁中的 go 版本要求改回 1.23
sed -i 's/^+go 1\.25\.0$/+go 1.23/' feeds/mosdns/v2dat/patches/*.patch feeds/mosdns/mosdns/patches/*.patch
