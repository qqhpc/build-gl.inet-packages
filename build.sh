#!/bin/sh
echo SOURCECODEURL: "$SOURCECODEURL"
echo PKGNAME: "$PKGNAME"
echo BOARD: "$BOARD"
EMAIL=${EMAIL:-"github-actions[bot]@github.com"}
echo EMAIL: "$EMAIL"
echo PASSWORD: "$PASSWORD"

WORKDIR="$(pwd)"

sudo -E apt-get update
sudo -E apt-get install git  asciidoc bash bc binutils bzip2 fastjar flex gawk gcc genisoimage gettext git intltool jikespg libgtk2.0-dev libncurses5-dev libssl1.0-dev make mercurial patch perl-modules python2.7-dev rsync ruby sdcc subversion unzip util-linux wget xsltproc zlib1g-dev zlib1g-dev -y

git config --global user.email "${EMAIL}"
git config --global user.name "github-actions[bot]"
[ -n "${PASSWORD}" ] && git config --global user.password "${PASSWORD}"

mkdir -p  ${WORKDIR}/buildsource
cd  ${WORKDIR}/buildsource
git clone "$SOURCECODEURL"
cd  ${WORKDIR}


mips_siflower_sdk_get()
{
	 git clone https://github.com/qqhpc/openwrt-sdk-siflower-1806.git openwrt-sdk
}

axt1800_sdk_get()
{
	mkdir -p ${WORKDIR}/openwrt-sdk
	git clone https://github.com/qqhpc/openwrt-sdk.git ${WORKDIR}/openwrt-sdk
	echo src-git packages https://git.openwrt.org/feed/packages.git^78bcd00c13587571b5c79ed2fc3363aa674aaef7 >${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git routing https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git telephony https://git.openwrt.org/feed/telephony.git^0183c1adda0e7581698b0ea4bff7c08379acf447 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git luci https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	
	sed -i '246,258d' ${WORKDIR}/openwrt-sdk/include/package-ipkg.mk
}



case "$BOARD" in
	"SF1200" |\
	"SFT1200" )
		mips_siflower_sdk_get
	;;
	"AXT1800" )
		axt1800_sdk_get
	;;
	*)
esac

cd openwrt-sdk
sed -i "1i\src-link githubaction ${WORKDIR}/buildsource" feeds.conf.default

ls -l
cat feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a
echo CONFIG_ALL=y >.config
make defconfig
make V=s ./package/feeds/githubaction/${PKGNAME}/compile

find bin -type f -exec ls -lh {} \;
find bin -type f -name "*.ipk" -exec cp -f {} "${WORKDIR}" \; 
