# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..13} )

DISTUTILS_USE_PEP517=pdm-backend

inherit distutils-r1 pypi

DESCRIPTION="FastAPI is a modern, fast (high-performance), web framework for building APIs with Python based on standard Python type hints."
HOMEPAGE="https://fastapi.tiangolo.com/"

LICENSE="MIT"
SLOT="0"
#IUSE=""
#REQUIRED_USE=""

BEPEND="
	virtual/pkgconfig
	>=dev-python/cython-0.24.0[${PYTHON_USEDEP}]
"
#DEPEND=""
#RDEPEND="${DEPEND}"

DISTUTILS_IN_SOURCE_BUILD=

distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/fastapi/fastapi"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
	S="${WORKDIR}/${MY_P}"
else
	MY_PV=${PV//_}
	MY_P=${PN}-${MY_PV}

#	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"
    SRC_URI="https://github.com/fastapi/fastapi/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/${MY_P}"
fi


python_prepare_all() {
	distutils-r1_python_prepare_all
}

python_compile() {
    distutils-r1_python_compile
}

python_install_all() {
	distutils-r1_python_install_all
}
