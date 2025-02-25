#!/bin/sh
echo SOURCECODEURL: "$SOURCECODEURL"
echo COMMITHASH: "$COMMITHASH"
echo BOARD: "$BOARD"

WORKDIR="$(pwd)"

sudo -E apt-get update
sudo -E apt-get install git libsystemd-dev asciidoc bash bc binutils bzip2 fastjar flex gawk gcc genisoimage gettext git intltool jikespg libgtk2.0-dev libncurses5-dev libssl-dev make mercurial patch perl-modules python2.7-dev rsync ruby sdcc subversion unzip util-linux wget xsltproc zlib1g-dev zlib1g-dev -y

mkdir -p  ${WORKDIR}/buildsource && cd  ${WORKDIR}/buildsource

git clone "$SOURCECODEURL" ot-br-posix
cd ot-br-posix
[ -n "${COMMITHASH}" ] && git checkout ${COMMITHASH}
git submodule update --init --recursive

cd  ${WORKDIR}


mips_siflower_sdk_get()
{
	 git clone https://github.com/gl-inet-builder/openwrt-sdk-siflower-1806.git openwrt-sdk
}

axt1800_sdk_get()
{
	wget -q -O openwrt-sdk.tar.xz https://fw.gl-inet.com/releases/v21.02-SNAPSHOT/sdk/openwrt-sdk-ipq807x-ipq60xx_gcc-5.5.0_musl_eabi.Linux-x86_64.tar.xz
	mkdir -p ${WORKDIR}/openwrt-sdk
	tar -Jxf openwrt-sdk.tar.xz -C ${WORKDIR}/openwrt-sdk --strip=1
	echo src-git packages https://git.openwrt.org/feed/packages.git^78bcd00c13587571b5c79ed2fc3363aa674aaef7 >${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git routing https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git telephony https://git.openwrt.org/feed/telephony.git^0183c1adda0e7581698b0ea4bff7c08379acf447 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git luci https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	
	sed -i '246,258d' ${WORKDIR}/openwrt-sdk/include/package-ipkg.mk
}

mt7981_sdk_get()
{
	 git clone https://github.com/gl-inet-builder/openwrt-sdk-mt7981.git  openwrt-sdk
}


case "$BOARD" in
	"SF1200" |\
	"SFT1200" )
		mips_siflower_sdk_get
	;;
	"AX1800" |\
	"AXT1800" )
		axt1800_sdk_get
	;;
	"MT3000" |\
	"MT2500" )
		mt7981_sdk_get
	;;
	*)
esac

cd openwrt-sdk
echo src-link openthread "${WORKDIR}/buildsource/ot-br-posix/etc/openwrt" >> feeds.conf.default

ls -l
cat feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

make defconfig
make -j1 V=sc package/openthread-br/compile

find bin -type f -exec ls -lh {} \;
find bin -type f -name "*.ipk" -exec cp -f {} "${WORKDIR}" \; 
