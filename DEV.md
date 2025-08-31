# H3C NX30 Pro 刷 114M 大分区

> 硬件信息：
> CPU: MT7981B
> RAM: 256MB
> ROM: 128MB

H3C NX30 Pro在OpenWRT官方支持列表中，对于想玩OpenWRT的用户来说是非常好的选择，不过OpenWRT官方编译的固件ROM分区有限制，可用于安装软件的分区只有10M左右，安装软件空间不足。

OpenWRT仓库中有PR更改ROM分区，扩大到114MB，但PR一直没有合进主干，自已动手编译。


## 1. 编译固件

### 1.1 Build环境

见 Dockerfile + docker-compose.yaml，启动后登录到容器中操作就行

### 1.2 Build 配置文件

核心配置文件有：
- .config
- feeds.conf.default

.config 配置文件从官方build仓库中下载后，使用 `make menuconfig` 修改配置即可。
feeds.conf.default 直接从官方仓库下载使用。https://downloads.openwrt.org/releases/24.10.2/targets/mediatek/filogic/


脚本：

```bash
./scripts/feeds update -a && ./scripts/feeds install -a

wget https://downloads.openwrt.org/releases/24.10.2/targets/mediatek/filogic/config.buildinfo -O .config

make menuconfig  => Target Profile Select `H3C NX30 Pro(ubootmod)`

make -j4 V=s
```

产出文件：

```
ls bin/target/mediatek/filogic/
```

====

1. 修改 TargetProfile 为 H3C NX30 Pro 114B
2. 去掉 Image Builder & SDK
3. 修改 Version Code 为 24.10.2
4. 修改 opkg instead apk
5. 修改内核 6.6.93，默认的 6.6.95-1-42059a7a690001cb2b81a20822308b67 无法安装软件
  #CONFIG_HAS_TESTING_KERNEL=y
~5. 修改 mirror~
6. 下载 feeds.conf.default，确保为 24.10.2

```bash
make clean
./scripts/feeds update -a
./scripts/feeds install -a
make -j4 V=s
```


====

V1 Bug

1. 包管理器使用了apk，导致无法安装软件

> make menuconfig  # 修复 Base 下包管理器，去掉apk，勾选opkg

2. Frimware Version 展示 OpenWrt SNAPSHOT r30265-4e0d1b6a4f0

~在编译时指定版本号：~
> echo "24.10.2" > version.code

在 make menuconfig 中搜索 Version Number，填入


3. 只编译固件，不编译sdk、image builder


menuconfig 设置：
Global build settings → 去掉 image builder / sdk 选中

====


# 2. 刷机流程：

1. 解锁MTD
```
opkg update
opkg install kmod-mtd-rw
insmod /lib/modules/$(uname -r)/mtd-rw.ko i_want_a_brick=1
```


2. 刷写uboot
```
mtd write /tmp/ubootmod-preloader.bin BL2
mtd write /tmp/ubootmod-bl31-uboot.fip FIP
```

3. 刷写过渡固件
```
sysupgrade -n ubootmod-initramfs-recovery.itb
```


4. 刷写正式固件
```
sysupgrade -n /tmp/openwrt-mediatek-filogic-h3c_magic-nx30-pro-ubootmod-squashfs-sysupgrade.bin
```


===

安装sftp server以便scp

```
opkg update
opkg install openssh-sftp-server
```


引用：

* https://github.com/Yiffyi/openwrt/tree/main
* https://github.com/hanwckf/immortalwrt-mt798x
* https://v2ex.com/t/962550
* https://xiaosong.fun/2023/10/15/openwrt-compile/
* https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
* https://www.acwifi.net/24565.html