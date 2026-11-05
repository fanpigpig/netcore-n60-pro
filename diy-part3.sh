#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Update feeds)
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# Netcore N60 Pro 512ROM 机型移植（官方 ImmortalWrt 25.12，mediatek/filogic）。
#
# 本脚本在工作流的 "Load custom configuration" 步骤中运行（工作目录为 openwrt
# 源码根目录），且在 make defconfig 之前执行，因此新增的设备符号可以在
# defconfig 时被正确识别。
#
# 完成两件事：
#   1. 写入 target/linux/mediatek/dts/mt7986a-netcore-n60pro-512rom.dts
#      （以官方 25.12 的 mt7986a-netcore-n60-pro.dts 为蓝本，内存改为 2 GiB，
#      ubi 分区扩大为 490 MiB，适配硬改后的 512 MiB SPI-NAND；NAND 分区沿用
#      25.12 树内 stock 布局家族的 mediatek,nmbm + fixed-partitions 写法）
#   2. 向 target/linux/mediatek/image/filogic.mk 追加 netcore_n60pro-512rom
#      设备定义，布局参数与之前验证过的 21.02 构建保持一致：
#        sysupgrade-tar + metadata（本自定义布局不用 FIT/.itb），
#        IMAGE_SIZE=501760k，UBINIZE_OPTS=-E 5，BLOCKSIZE=128k，
#        PAGESIZE=2048，KERNEL_IN_UBI=1。

set -e

DTS_FILE="target/linux/mediatek/dts/mt7986a-netcore-n60pro-512rom.dts"
IMAGE_MK="target/linux/mediatek/image/filogic.mk"

echo "==> 写入 512ROM 设备树：$DTS_FILE"
cat > "$DTS_FILE" <<'DTS_EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
#include <dt-bindings/pinctrl/mt65xx.h>

#include "mt7986a.dtsi"

/ {
	model = "Netcore N60Pro 512ROM versions";
	compatible = "netcore,n60pro-512rom", "mediatek,mt7986a";

	aliases {
		serial0 = &uart0;
		led-boot = &led_power;
		led-failsafe = &led_power;
		led-running = &led_power;
		led-upgrade = &led_power;
		label-mac-device = &gmac0;
	};

	chosen {
		stdout-path = "serial0:115200n8";
	};

	memory@40000000 {
		reg = <0 0x40000000 0 0x80000000>;
		device_type = "memory";
	};

	gpio-keys {
		compatible = "gpio-keys";

		button-reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 9 GPIO_ACTIVE_LOW>;
		};

		button-mesh {
			label = "mesh";
			linux,code = <KEY_WPS_BUTTON>;
			gpios = <&pio 10 GPIO_ACTIVE_LOW>;
		};
	};

	gpio-leds {
		compatible = "gpio-leds";

		led-0 {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_WLAN;
			gpios = <&pio 1 GPIO_ACTIVE_LOW>;
			linux,default-trigger = "phy1tpt";
		};

		led_power: led-1 {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_POWER;
			gpios = <&pio 29 GPIO_ACTIVE_LOW>;
		};

		led-2 {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_USB;
			gpios = <&pio 30 GPIO_ACTIVE_LOW>;
		};

		led-3 {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_WPS;
			gpios = <&pio 31 GPIO_ACTIVE_LOW>;
		};

		led-4 {
			color = <LED_COLOR_ID_BLUE>;
			function = LED_FUNCTION_WAN;
			gpios = <&pio 32 GPIO_ACTIVE_LOW>;
		};
	};

	reg_3p3v: regulator-3p3v {
		compatible = "regulator-fixed";
		regulator-name = "fixed-3.3V";
		regulator-min-microvolt = <3300000>;
		regulator-max-microvolt = <3300000>;
		regulator-boot-on;
		regulator-always-on;
	};

	reg_5v: regulator-5v {
		compatible = "regulator-fixed";
		regulator-name = "fixed-5V";
		regulator-min-microvolt = <5000000>;
		regulator-max-microvolt = <5000000>;
		regulator-boot-on;
		regulator-always-on;
	};
};

&crypto {
	status = "okay";
};

&eth {
	status = "okay";

	gmac0: mac@0 {
		compatible = "mediatek,eth-mac";
		reg = <0>;
		phy-mode = "2500base-x";
		nvmem-cells = <&macaddr_factory_1fef20>;
		nvmem-cell-names = "mac-address";
		fixed-link {
			speed = <2500>;
			full-duplex;
			pause;
		};
	};

	gmac1: mac@1 {
		compatible = "mediatek,eth-mac";
		reg = <1>;
		phy-handle = <&phy6>;
		phy-mode = "2500base-x";
		nvmem-cells = <&macaddr_factory_1fef26>;
		nvmem-cell-names = "mac-address";
	};

	mdio: mdio-bus {
		#address-cells = <1>;
		#size-cells = <0>;
	};
};

&mdio {
	reset-delay-us = <600>;
	reset-post-delay-us = <20000>;
	reset-gpios = <&pio 6 GPIO_ACTIVE_LOW>;

	phy5: phy@5 {
		compatible = "ethernet-phy-ieee802.3-c45";
		reg = <5>;

		leds {
			#address-cells = <1>;
			#size-cells = <0>;

			led@3 {
				reg = <3>;
				color = <LED_COLOR_ID_GREEN>;
				function = LED_FUNCTION_LAN;
			};
		};
	};

	phy6: phy@6 {
		compatible = "ethernet-phy-ieee802.3-c45";
		reg = <6>;

		leds {
			#address-cells = <1>;
			#size-cells = <0>;

			led@3 {
				reg = <3>;
				color = <LED_COLOR_ID_GREEN>;
				function = LED_FUNCTION_WAN;
			};
		};
	};

	switch: switch@1f {
		compatible = "mediatek,mt7531";
		reg = <31>;
		reset-gpios = <&pio 5 GPIO_ACTIVE_HIGH>;
		interrupt-controller;
		#interrupt-cells = <1>;
		interrupt-parent = <&pio>;
		interrupts = <66 IRQ_TYPE_LEVEL_HIGH>;
	};
};

&switch {
	ports {
		#address-cells = <1>;
		#size-cells = <0>;

		port@0 {
			reg = <0>;
			label = "lan2";
		};

		port@3 {
			reg = <3>;
			label = "lan3";
		};

		port@4 {
			reg = <4>;
			label = "lan4";
		};

		port@5 {
			reg = <5>;
			label = "lan1";
			phy-mode = "2500base-x";
			phy-handle = <&phy5>;
		};

		port@6 {
			reg = <6>;
			ethernet = <&gmac0>;
			phy-mode = "2500base-x";
			fixed-link {
				speed = <2500>;
				full-duplex;
				pause;
			};
		};
	};
};

&spi0 {
	pinctrl-names = "default";
	pinctrl-0 = <&spi_flash_pins>;
	status = "okay";

	flash@0 {
		compatible = "spi-nand";
		reg = <0>;
		spi-max-frequency = <20000000>;
		spi-tx-bus-width = <4>;
		spi-rx-bus-width = <4>;

		mediatek,nmbm;
		mediatek,bmt-max-ratio = <1>;
		mediatek,bmt-max-reserved-blocks = <64>;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "bl2";
				reg = <0x0 0x100000>;
				read-only;
			};

			partition@100000 {
				label = "u-boot-env";
				reg = <0x100000 0x80000>;
			};

			partition@180000 {
				label = "factory";
				reg = <0x180000 0x200000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					eeprom_factory_0: eeprom@0 {
						reg = <0x0 0x1000>;
					};

					macaddr_factory_1fef20: macaddr@1fef20 {
						reg = <0x1fef20 0x6>;
					};

					macaddr_factory_1fef26: macaddr@1fef26 {
						reg = <0x1fef26 0x6>;
					};
				};
			};

			partition@380000 {
				label = "fip";
				reg = <0x380000 0x200000>;
				read-only;
			};

			partition@580000 {
				label = "ubi";
				reg = <0x0580000 0x1ea00000>;
			};
		};
	};
};

&pio {
	spi_flash_pins: spi-flash-pins-33-to-38 {
		mux {
			function = "spi";
			groups = "spi0", "spi0_wp_hold";
		};
		conf-pu {
			pins = "SPI2_CS", "SPI2_HOLD", "SPI2_WP";
			drive-strength = <MTK_DRIVE_8mA>;
			bias-disable; /* bias-disable */
		};
		conf-pd {
			pins = "SPI2_CLK", "SPI2_MOSI", "SPI2_MISO";
			drive-strength = <MTK_DRIVE_8mA>;
			bias-disable; /* bias-disable */
		};
	};

	wf_2g_5g_pins: wf_2g_5g-pins {
		mux {
			function = "wifi";
			groups = "wf_2g", "wf_5g";
		};
		conf {
			pins = "WF0_HB1", "WF0_HB2", "WF0_HB3", "WF0_HB4",
			       "WF0_HB0", "WF0_HB0_B", "WF0_HB5", "WF0_HB6",
			       "WF0_HB7", "WF0_HB8", "WF0_HB9", "WF0_HB10",
			       "WF0_TOP_CLK", "WF0_TOP_DATA", "WF1_HB1",
			       "WF1_HB2", "WF1_HB3", "WF1_HB4", "WF1_HB0",
			       "WF1_HB5", "WF1_HB6", "WF1_HB7", "WF1_HB8",
			       "WF1_TOP_CLK", "WF1_TOP_DATA";
			drive-strength = <MTK_DRIVE_4mA>;
		};
	};
};

&ssusb {
	vusb33-supply = <&reg_3p3v>;
	vbus-supply = <&reg_5v>;
	status = "okay";
};

&trng {
	status = "okay";
};

&uart0 {
	status = "okay";
};

&usb_phy {
	status = "okay";
};

&watchdog {
	status = "okay";
};

&wifi {
	nvmem-cells = <&eeprom_factory_0>;
	nvmem-cell-names = "eeprom";
	pinctrl-names = "default";
	pinctrl-0 = <&wf_2g_5g_pins>;
	status = "okay";
};
DTS_EOF

echo "==> 向 $IMAGE_MK 追加 512ROM 设备定义"
cat >> "$IMAGE_MK" <<'MK_EOF'

define Device/netcore_n60pro-512rom
  DEVICE_VENDOR := Netcore
  DEVICE_MODEL := Netcore N60Pro 512ROM versions
  DEVICE_DTS := mt7986a-netcore-n60pro-512rom
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware kmod-usb3 automount
  SUPPORTED_DEVICES += netcore,n60pro-512rom
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 501760k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += netcore_n60pro-512rom
MK_EOF

echo "==> 512ROM 机型移植完成。"

# mosdns / luci-app-mosdns init 脚本冲突修复（#7 失败根因）：
# ImmortalWrt packages 源的 mosdns 5.3.3 会把上游自带的
# scripts/openwrt/mosdns-init-openwrt 装为 /etc/init.d/mosdns，
# 而 sbwml 的 luci-app-mosdns 自带 root/etc/init.d/mosdns，
# 两包同时选中时 apk 拒绝覆盖，导致 package/install 失败。
# luci-app-mosdns 的 init 脚本是功能完整的那个，保留它；
# 这里只删 mosdns 包里的那一行安装命令（若 mosdns 来自 sbwml 源
# 本身不带 init 脚本，则以下命令是空操作）。
echo "==> 去除 mosdns 包自带的 init 脚本（避免与 luci-app-mosdns 冲突）"
for _mosdns_mk in package/feeds/packages/mosdns/Makefile feeds/packages/net/mosdns/Makefile; do
	if [ -f "$_mosdns_mk" ]; then
		sed -i '/mosdns-init-openwrt/d' "$_mosdns_mk"
	fi
done
