# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
EAPI=8
#
DESCRIPTION="Orca Slicer is a free 3D printing slicer created by SoftFever."
#
HOMEPAGE="https://orca-slicer.com/"
#
SRC_URI="https://github.com/SoftFever/OrcaSlicer/releases/download/v${PV}/OrcaSlicer_Linux_V${PV}.AppImage"
#
S="${WORKDIR}"
#
LICENSE="GPL-3"
#
SLOT="0"
#
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
#
#IUSE=""
#
RESTRICT="strip"
#
RDEPEND="sys-fs/fuse:0 \
net-libs/webkit-gtk:4 \
media-libs/gstreamer \
media-libs/gst-plugins-base"
#
QA_PREBUILT="*"
#
src_install() {
mkdir -p "${D}/usr/share/icons/hicolor/192x192/apps/"
mkdir -p "${D}/usr/share/applications/"
cp -f "${FILESDIR}/OrcaSlicer-bin.png" "${D}/usr/share/icons/hicolor/192x192/apps/"
cp -f "${FILESDIR}/orcaslicer-bin.desktop" "${D}/usr/share/applications/"
cp "${DISTDIR}/OrcaSlicer_Linux_V${PV}.AppImage" orcaslicer-bin || die
dobin orcaslicer-bin
}
