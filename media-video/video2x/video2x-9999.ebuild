# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake-multilib git-r3

DESCRIPTION="A machine learning-based video super resolution and frame interpolation framework"
HOMEPAGE="https://github.com/k4yt3x/video2x"

LICENSE="AGPL-3.0-only"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="
+openmp
"
# It compiles those anyways...
#+realesrgan
#+waifu

REQUIRED_USE=""

DEPEND="
	dev-vcs/git
    sys-devel/gcc
    openmp? ( >=sys-devel/gcc-4.2 )
    openmp? ( sys-devel/gcc[openmp] )
    media-video/ffmpeg
    dev-libs/ncnn[vulkan]
    openmp? ( dev-libs/ncnn[openmp] )
    openmp? ( llvm-runtimes/openmp )
    media-libs/vulkan-loader
    dev-libs/spdlog
    dev-libs/boost
"
# It compiles those anyways...
#realesrgan? ( media-gfx/realesrgan-ncnn-vulkan )
#waifu? ( media-gfx/waifu2x-ncnn-vulkan )

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

EGIT_REPO_URI="https://github.com/k4yt3x/video2x.git"
EGIT_BRANCH="master"
EGIT_CLONE_TYPE="single"
EGIT_SUBMODULES=( '*' )

if [[ ${PV} == 9999 ]]; then
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="video2x"
    S="${WORKDIR}/video2x-${MY_PV}"
else
    EGIT_COMMIT="${PV}"
	SRC_URI=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="video2x"
    S="${WORKDIR}/video2x-${MY_PV}"

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
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=/usr
        -DCMAKE_CXX_COMPILER=clang++
        -DVIDEO2X_ENABLE_X86_64_V3=ON
    )
    cmake-multilib_src_configure
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    default
    cmake-multilib_src_install
}
