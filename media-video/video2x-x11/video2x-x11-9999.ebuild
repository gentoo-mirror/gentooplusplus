# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake-multilib git-r3

DESCRIPTION="The Qt6 graphical user interface for Video2X."
HOMEPAGE="https://github.com/k4yt3x/video2x-qt6"

LICENSE="AGPL-3.0-only"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="
"

REQUIRED_USE=""

DEPEND="
    dev-libs/spdlog
    media-video/video2x
    dev-qt/qtbase:6
    dev-qt/qtsvg:6
    dev-qt/qttools:6[qtdiag,vulkan]
"

BEPEND="virtual/pkgconfig
    dev-util/ccache
    llvm-core/clang
    dev-util/vulkan-headers
    dev-libs/boost"

RDEPEND="
"

BDEPEND="
"
DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/usr"

EGIT_REPO_URI="https://github.com/k4yt3x/video2x-qt6.git"
EGIT_BRANCH="master"
EGIT_CLONE_TYPE="single"
EGIT_SUBMODULES=( '* -video2x' )

if [[ ${PV} == 9999 ]]; then
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="video2x-x11"
    S="${WORKDIR}/video2x-x11-${MY_PV}"
else
    EGIT_COMMIT="${PV}"
	SRC_URI=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="video2x-x11"
    S="${WORKDIR}/video2x-x11-${MY_PV}"
fi

_adjust_sandbox() {
	addpredict /usr
}

src_prepare() {
	cmake_src_prepare
}

src_configure() {
	die() { echo "$*" 1>&2 ; exit 1; }
    local mycmakeargs=(
        -DCMAKE_BUILD_TYPE=None
        -DCMAKE_INSTALL_PREFIX=/usr
        -DCMAKE_CXX_COMPILER=clang++
        -DVIDEO2X_ENABLE_NATIVE=ON
        -DUSE_EXTERNAL_VIDEO2X=ON
    )
    cmake-multilib_src_configure
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    default
    cmake-multilib_src_install
}
