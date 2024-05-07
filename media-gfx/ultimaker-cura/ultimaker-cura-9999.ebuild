# Copyright 1999-2024 Eugeniusz Gienek
# Distributed under the terms of the GNU General Public License v3

EAPI="8"

PYTHON_COMPAT=( pypy3 python3_{10..11} )
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

if [[ ${PV} == *9999* ]]; then
    S="${WORKDIR}/${MY_PN}"
    EGIT_REPO_URI="https://github.com/Ultimaker/Cura.git"
    EGIT_BRANCH="main"
    EGIT_CHECKOUT_DIR="./Cura"
    inherit git-r3
else
    S=${WORKDIR}/${PN}-${P}
    SRC_URI="$(pypi_sdist_url --no-normalize)
    https://github.com/Ultimaker/Cura/archive/refs/tags/${PV}.tar.gz -> ${PV}.gh.tar.gz"
fi

DESCRIPTION="Ultimaker Cura - slicer for 3D printing"
HOMEPAGE="https://github.com/Eugeniusz-Gienek/gentoo-ultimaker-cura.git"
#SRC_URI="https://github.com/Ultimaker/Cura.git"

# Source directory; the dir where the sources can be found (automatically
# unpacked) inside ${WORKDIR}.  The default value for S is ${WORKDIR}/${P}
# If you don't need to change it, leave the S= line out of the ebuild
# to keep it tidy.
#S="${WORKDIR}/${P}"

LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64"
IUSE="python_targets_python3_10 +python_targets_python3_11"
#REQUIRED_USE"^^ ( python_targets_python3_10 python_targets_python3_11 )"
RESTRICT=""

RDEPEND="${PYTHON_DEPS}
dev-lang/python:3.10
|| ( dev-lang/python:3.10 dev-lang/python:3.11 )
dev-python/virtualenv
dev-vcs/git"
DEPEND="${RDEPEND}"
BDEPEND=">=sys-devel/gcc-11"

RUN_SBIN_COMMAND="run_ultimaker_cura_${PV}"

#src_prepare() {
#	eapply_user
#	distutils-r1_src_prepare
#}

#src_prepare() {
#    true
#}

#python_prepare_all() {
#    distutils-r1_python_prepare_all
#}


#S="${WORKDIR}"

DISABLE_AUTOFORMATTING=1
DOC_CONTENTS="
Cura is installed here: ${INSTALL_DIR}
In order to run using nvidia card - pass the parameter \"--nvidia\" to the executable.
"

#DOCS="README.rst"

src_compile() {
	true
}

python_install() {
    #true
    #distutils-r1_python_install
    dodir "$INSTALL_DIR"
    dodir "$INSTALL_DIR/Cura"
    cp -Rpvf "${S}/" "${D}/"
    insinto /opt/
    doins -r opt/*
    #readme.gentoo_create_doc
}

src_unpack() {
    #Use the highest python version possible. If not, fallback to lower one
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
    #dodoc ${DOCS}
    cp -Rpvf "${DISTDIR}"/ "${S}"
    "python${PY_UC}" -m venv "${S}/$INSTALL_DIR"
    VIRTUAL_ENV="$INSTALL_DIR" "${S}/$INSTALL_DIR/bin/python3" -m pip --no-cache-dir --quiet install conan==$CONAN_VER
    VIRTUAL_ENV="$INSTALL_DIR" "${S}/$INSTALL_DIR/bin/conan" config install $CONAN_INSTALLER_CONFIG_URL
    VIRTUAL_ENV="$INSTALL_DIR" "${S}/$INSTALL_DIR/bin/conan" profile new default --detect --force
    VIRTUAL_ENV="$INSTALL_DIR" "${S}/$INSTALL_DIR/bin/conan" profile update settings.compiler.libcxx=libstdc++11 default
    EGIT_CHECKOUT_DIR="${S}/$INSTALL_DIR/$EGIT_CHECKOUT_DIR"
    if [[ ${PV} == *9999* ]] ; then
        git-r3_checkout
    else
        unpack ${PV}.gh.tar.gz
    fi
    VIRTUAL_ENV="$INSTALL_DIR" "${S}/$INSTALL_DIR/bin/conan" install "${S}/$INSTALL_DIR/Cura" --build=missing --update -o cura:devtools=True -g VirtualPythonEnv
}

#src_prepare() {
    #for i in "${WORKDIR}"/*.patch ; do
    #    eapply "${i}"
    #done
    #eapply_user
    #distutils-r1_src_prepare
    #true
#}

python_install_all() {
    #distutils-r1_python_install_all
    dodir "$INSTALL_DIR"
    dodir "$INSTALL_DIR/Cura"
    cp -Rvf "${S}/" "${D}/"
    #emake DESTDIR="${D}" install
    elog "Creating Cura launcher..."
    #sed 's~CURA_INSTALL_DIR~'$INSTALL_DIR'~g' -i $FILESDIR/run_ultimaker_cura.sh
    #${FILESDIR}/run_ultimaker_cura.sh
    cp -vf "${FILESDIR}/run_ultimaker_cura.sh" "${T}/"
    fperms 0755 "${T}/run_ultimaker_cura.sh"
    fperms a+X "${T}/run_ultimaker_cura.sh"
    sed 's~CURA_INSTALL_DIR~'$INSTALL_DIR'~g' -i "${T}/run_ultimaker_cura.sh"
    newsbin "${T}/run_ultimaker_cura.sh" ${RUN_SBIN_COMMAND}
    readme.gentoo_create_doc
}


pkg_postinst() {
	elog "Ultimaker Cura requires python 3.10 or 3.11 to run. 3.12 and later are NOT YET supported."
	elog "Besides, in order to run it with python3.11 You still need.... 3.10 python executable."
	elog "Ultimate Cura was installed into a virtualenv built info ${INSTALL_DIR}"
	elog ""
	elog "In order to run it, please use the command \"${RUN_SBIN_COMMAND}\""
	elog ""
	elog "Hope it works. Enjoy!"
    readme.gentoo_print_elog
}
