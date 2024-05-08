# Copyright 1999-2024 Eugeniusz Gienek
# Distributed under the terms of the GNU General Public License v3

EAPI="8"

PYTHON_COMPAT=( python3_{10..11} )
PYTHON_REQ_USE=""
DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYPI_PN="ultimaker-cura"
inherit distutils-r1 pypi readme.gentoo-r1

MY_PN="ultimaker-cura"

CONAN_VER="1.64.0"
CONAN_INSTALLER_CONFIG_URL="https://github.com/ultimaker/conan-config.git"

PROPERTIES="live test_network"

SRC_URI=""

INSTALL_DIR="/opt/${MY_PN}/${PV}"

S="${WORKDIR}"

if [[ ${PV} == *9999* ]]; then
    EGIT_REPO_URI="https://github.com/Ultimaker/Cura.git"
    EGIT_BRANCH="main"
    EGIT_CHECKOUT_DIR="${INSTALL_DIR}/"
    inherit git-r3
else
    SRC_URI="$(pypi_sdist_url --no-normalize)
    https://github.com/Ultimaker/Cura/archive/refs/tags/${PV}.tar.gz -> ${PV}.gh.tar.gz"
fi

DESCRIPTION="Ultimaker Cura - slicer for 3D printing"
HOMEPAGE="https://github.com/Eugeniusz-Gienek/gentoo-ultimaker-cura.git"

LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64"
IUSE="python_targets_python3_10 +python_targets_python3_11"
#REQUIRED_USE"^^ ( python_targets_python3_10 python_targets_python3_11 )"
RESTRICT=""

RDEPEND="${PYTHON_DEPS}
sys-apps/util-linux
sys-apps/coreutils
dev-lang/python:3.10
|| ( dev-lang/python:3.10 dev-lang/python:3.11 )
dev-python/virtualenv
dev-vcs/git
=dev-python/node-semver-0.6.1
=dev-util/conan-1.64.0"
DEPEND="${RDEPEND}"
BDEPEND=">=sys-devel/gcc-11"

RUN_SBIN_COMMAND="run_ultimaker_cura_${PV}"

DISABLE_AUTOFORMATTING=1
DOC_CONTENTS="
Cura is installed here: ${INSTALL_DIR}
In order to run using nvidia card - pass the parameter \"--nvidia\" to the executable.
"

src_compile() {
	true
}

src_unpack() {
    PY_UC="3.11"
    PY_UC_D="3_11"
    if use python_targets_python3_10 ; then
        PY_UC="3.10"
        PY_UC_D="3_10"
    elif use python_targets_python3_11 ; then
        PY_UC="3.11"
        PY_UC_D="3_11"
    else
        eerror "Error: supported Python version is NOT specified."
    fi
    conan config install $CONAN_INSTALLER_CONFIG_URL
    conan profile new default --detect --force
    conan profile update settings.compiler.libcxx=libstdc++11 default
    EGIT_CHECKOUT_DIR="${S}$INSTALL_DIR"
    if [[ ${PV} == *9999* ]] ; then
        git-r3_checkout
    else
        unpack ${PV}.gh.tar.gz
    fi
    if [ ! -d "${EGIT_CHECKOUT_DIR}" ]; then
        die "Cannot get to the git checkout directory: ${EGIT_CHECKOUT_DIR}"
    fi
    cd "${EGIT_CHECKOUT_DIR}"
    conan install ./ --build=missing --update -o cura:devtools=True -g VirtualPythonEnv
    cd "${S}"
    find "${S}" -name '*.pth' -delete
}

python_install() {
    dodir "$INSTALL_DIR"
    dodir "$INSTALL_DIR/venv"
    dodir "$INSTALL_DIR/venv/bin"
    cd ${D}
    cp -Rpf "${S}/" "${D}/"
    cd ${D}
    cp -Rpf "${HOME}/.conan" "${D}$INSTALL_DIR/venv"
    cd "${S}/$INSTALL_DIR/"
    source venv/bin/activate
    CP3_10_INTERPRETER_ABS=`whereis python | awk '{print $2}'`
    CP3_10_INTERPRETER=`realpath -s --relative-to=${S} ${CP3_10_INTERPRETER_ABS}`
    source ${S}$INSTALL_DIR/venv/bin/deactivate_activate
    rm -f ${D}${INSTALL_DIR}/venv/bin/python3.10
    dosym ${CP3_10_INTERPRETER} ${INSTALL_DIR}/venv/bin/python3.10
}

python_install_all() {
    elog "Creating Cura launcher..."
    mkdir -p "${ED}/tmp"
    cp -f "${FILESDIR}/run_ultimaker_cura.sh" "${ED}/tmp/"
    fperms 0755 /tmp/run_ultimaker_cura.sh
    fperms a+X /tmp/run_ultimaker_cura.sh
    sed 's~CURA_INSTALL_DIR~'$INSTALL_DIR'~g' -i "${ED}/tmp/run_ultimaker_cura.sh"
    newsbin "${ED}/tmp/run_ultimaker_cura.sh" ${RUN_SBIN_COMMAND}
    rm -f "${ED}/tmp/run_ultimaker_cura.sh"
    rm -rf "${ED}/tmp"
    readme.gentoo_create_doc
}


pkg_postinst() {
    # We'll NOT update pyc-files, they will auto-generate anyways.
    find ${INSTALL_DIR} -name '*.pyc' -delete
    # Now, we have to update the paths in the create virtual environments
    cd ${T}
    TDIR=`pwd`
    cd ${S}
    SDIR=`pwd`
    cd ${HOME}
    HDIR=`pwd`
    find . -type f -exec sed -i 's~'${SDIR}'~''~g' {} +
    cd ${INSTALL_DIR}/venv/bin
    find . -type f -exec sed -i 's~'${SDIR}'~''~g' {} +
    cd ${INSTALL_DIR}/venv/.conan
    find . -type f -exec sed 's~'${HDIR}'~'${INSTALL_DIR}/venv/'~g' {} +
	#elog "Ultimaker Cura requires python 3.10 or 3.11 to run. 3.12 and later are NOT YET supported."
	#elog "Besides, in order to run it with python3.11 You still need.... 3.10 python executable."
	elog "Ultimate Cura was installed into a virtualenv built info ${INSTALL_DIR}"
	elog ""
	elog "In order to run it, please use the command \"${RUN_SBIN_COMMAND}\""
	elog ""
	elog "Hope it works. Enjoy!"
    readme.gentoo_print_elog
}
