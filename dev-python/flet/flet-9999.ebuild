# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..13} )

DISTUTILS_USE_PEP517=poetry

inherit distutils-r1 pypi

DESCRIPTION="Flet is a framework that enables you to easily build real-time apps."
HOMEPAGE="https://flet.dev/"

LICENSE="Apache-2.0"
SLOT="0"
#IUSE=""
#REQUIRED_USE=""

BEPEND="
	virtual/pkgconfig
	>=dev-python/cython-0.24.0[${PYTHON_USEDEP}]
	>=dev-python/poetry-core-2.0.0[${PYTHON_USEDEP}]
"
DEPEND="
    >=dev-python/poetry-core-2.0.0[${PYTHON_USEDEP}]
    dev-python/repath[${PYTHON_USEDEP}]
    dev-python/toml[${PYTHON_USEDEP}]
    dev-python/rich[${PYTHON_USEDEP}]
    dev-python/qrcode[${PYTHON_USEDEP}]
    dev-python/watchdog[${PYTHON_USEDEP}]
    dev-util/cookiecutter[${PYTHON_USEDEP}]
    "
RDEPEND="${DEPEND}"

DISTUTILS_IN_SOURCE_BUILD=

distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/flet-dev/flet"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
	S="${WORKDIR}/${MY_P}/flet-9999/sdk/python"
else
	MY_PV=${PV//_}
	MY_P=${PN}-${MY_PV}

#	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"
    SRC_URI="https://github.com/flet-dev/flet/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/${MY_P}/sdk/python"
fi


python_prepare_all() {
	distutils-r1_python_prepare_all
}

python_compile() {
	cd "${S}/packages/flet"
    distutils-r1_python_compile
    cd "${S}/packages/flet-cli"
	distutils-r1_python_compile
	cd "${S}/packages/flet-desktop"
	distutils-r1_python_compile
	cd "${S}/packages/flet-web"
    distutils-r1_python_compile
}

python_install_all() {
    cd "${S}/packages/flet"
	distutils-r1_python_install_all
    cd "${S}/packages/flet-cli"
	distutils-r1_python_install_all
    cd "${S}/packages/flet-desktop"
	distutils-r1_python_install_all
    cd "${S}/packages/flet-web"
	distutils-r1_python_install_all
}
