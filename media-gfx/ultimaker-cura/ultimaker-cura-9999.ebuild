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

S="${WORKDIR}/${MY_PN}"

if [[ ${PV} == *9999* ]]; then
    EGIT_REPO_URI="https://github.com/Ultimaker/Cura.git"
    EGIT_BRANCH="main"
    EGIT_CHECKOUT_DIR="${INSTALL_DIR}/Cura"
    inherit git-r3
else
    SRC_URI="$(pypi_sdist_url --no-normalize)
    https://github.com/Ultimaker/Cura/archive/refs/tags/${PV}.tar.gz -> ${PV}.gh.tar.gz"
fi

DESCRIPTION="Ultimaker Cura - slicer for 3D printing"
HOMEPAGE="https://github.com/Eugeniusz-Gienek/gentoo-ultimaker-cura.git"
#SRC_URI="https://github.com/Ultimaker/Cura.git"

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
dev-vcs/git"
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
    cp -Rpf "${DISTDIR}"/ "${T}"
    "python${PY_UC}" -m venv "${T}/$INSTALL_DIR"
    VIRTUAL_ENV="$INSTALL_DIR" "${T}/$INSTALL_DIR/bin/python3" -m pip --no-cache-dir --quiet install conan==$CONAN_VER
    VIRTUAL_ENV="$INSTALL_DIR" "${T}/$INSTALL_DIR/bin/conan" config install $CONAN_INSTALLER_CONFIG_URL
    VIRTUAL_ENV="$INSTALL_DIR" "${T}/$INSTALL_DIR/bin/conan" profile new default --detect --force
    VIRTUAL_ENV="$INSTALL_DIR" "${T}/$INSTALL_DIR/bin/conan" profile update settings.compiler.libcxx=libstdc++11 default
    EGIT_CHECKOUT_DIR="${T}/$EGIT_CHECKOUT_DIR"
    if [[ ${PV} == *9999* ]] ; then
        git-r3_checkout
    else
        unpack ${PV}.gh.tar.gz
    fi
    VIRTUAL_ENV="$INSTALL_DIR" "${T}/$INSTALL_DIR/bin/conan" install "${T}/$INSTALL_DIR/Cura" --build=missing --update -o cura:devtools=True -g VirtualPythonEnv
    #cd "${WORKDIR}"
    #find ./ -mindepth 1 ! -regex '^./'${MY_PN}'\(/.*\)?' -delete
    find "${T}" -name '*.pth' -delete
}

python_install() {
    #cd "${S}/$INSTALL_DIR/Cura/"
    #source venv/bin/activate
    #CP3_10_INTERPRETER_ABS=`whereis python | awk '{print $2}'`
    #CP3_10_INTERPRETER=`realpath -s --relative-to=${S} ${CP3_10_INTERPRETER_ABS}`
    #source ${S}/$INSTALL_DIR/Cura/venv/bin/deactivate_activate
    dodir "$INSTALL_DIR"
    dodir "$INSTALL_DIR/Cura"
    dodir "$INSTALL_DIR/Cura/venv"
    dodir "$INSTALL_DIR/Cura/venv/bin"
    #find "${T}" -name '*.pth' -delete
    cp -Rpf "${T}/$INSTALL_DIR" "${D}/$INSTALL_DIR"
    cp -Rpf "${HOME}/.conan" "${D}/$INSTALL_DIR/Cura/venv/.conan"
    cd ${D}
    insinto /opt/
    #doins -r opt/*
    cd "${T}/$INSTALL_DIR/Cura/"
    source venv/bin/activate
    CP3_10_INTERPRETER_ABS=`whereis python | awk '{print $2}'`
    CP3_10_INTERPRETER=`realpath -s --relative-to=${T} ${CP3_10_INTERPRETER_ABS}`
    source ${T}/$INSTALL_DIR/Cura/venv/bin/deactivate_activate
    rm -f ${D}/${INSTALL_DIR}/Cura/venv/bin/python3.10
    dosym ${CP3_10_INTERPRETER} ${INSTALL_DIR}/Cura/venv/bin/python3.10
    #rm -vf ${INSTALL_DIR}/Cura/venv/bin/python*
    # Here we have to have.... Python 3.10
    #P3_10_INTERPRETER=`whereis python3.10 | awk '{print $2}'`
    #dosym ${P3_10_INTERPRETER} ${INSTALL_DIR}/Cura/venv/bin/python
    #dosym ${P3_10_INTERPRETER} ${INSTALL_DIR}/Cura/venv/bin/python3
    #dosym ${P3_10_INTERPRETER} ${INSTALL_DIR}/Cura/venv/bin/python3.10

}

python_install_all() {
    #dodir "$INSTALL_DIR"
    #dodir "$INSTALL_DIR/Cura"
    #find "${S}" -name '*.pth' -delete
    #cp -Rf "${S}/$INSTALL_DIR" "${D}/$INSTALL_DIR"
    #cp -Rpf "${HOME}/.conan" "${D}/$INSTALL_DIR/Cura/venv/.conan"
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
    # First of all, we have to fix the paths for parent Python environment
    "python${PY_UC}" -m venv "$INSTALL_DIR"
    #python3.10 -m venv "$INSTALL_DIR/Cura/venv"
    # We'll NOT update pyc-files, they will auto-generate anyways.
    find ${INSTALL_DIR} -name '*.pyc' -delete
    # Now, we have to update the paths in the create virtual environments
    cd ${T}
    TDIR=`pwd`
    cd ${HOME}
    HDIR=`pwd`
    cd ${INSTALL_DIR}/bin
    #find . -type f -exec sed 's~'${TDIR}'~'${INSTALL_DIR}'~g' {} +
    find . -type f -exec sed -i 's~'${TDIR}'~''~g' {} +
    cd ${INSTALL_DIR}/Cura/venv/bin
    find . -type f -exec sed -i 's~'${TDIR}'~''~g' {} +
    cd ${INSTALL_DIR}/Cura/venv/.conan
    find . -type f -exec sed 's~'${HDIR}'~'${INSTALL_DIR}/Cura/venv/'~g' {} +
	#elog "Ultimaker Cura requires python 3.10 or 3.11 to run. 3.12 and later are NOT YET supported."
	#elog "Besides, in order to run it with python3.11 You still need.... 3.10 python executable."
	elog "Ultimate Cura was installed into a virtualenv built info ${INSTALL_DIR}"
	elog ""
	elog "In order to run it, please use the command \"${RUN_SBIN_COMMAND}\""
	elog ""
	elog "Hope it works. Enjoy!"
    readme.gentoo_print_elog
}
