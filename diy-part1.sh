#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Add ADGuardHome source
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/luci-app-adguardhome
chmod -R 755 ./package/luci-app-adguardhome/*
# Add PassWall2 feed (official, supports OpenWrt 21.02+)
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2' >>feeds.conf.default
# Add mosdns feed (official, openwrt-21.02 branch)
echo 'src-git mosdns https://github.com/sbwml/luci-app-mosdns;openwrt-21.02' >>feeds.conf.default
