# Based on ex_repo version - many thanks to their contribution!
# Copyright 2025 Arniiiii lg3dx6fd@gmail.com and wadewilson619 at discord
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=6.4

PYTHON_COMPAT=( python3_{11..12} )

inherit systemd cmake-multilib cuda rocm python-single-r1

DESCRIPTION="Llama.cpp - LLM inference in C/C++."
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~arm64-macos ~loong ~riscv ~x64-macos ~x86 ~x86-macos"

# BLAS - OpenBLAS, BLIS, Intel oneMKL
# Musa: this provides GPU acceleration using a Moore Threads GPU. Make sure to have the MUSA SDK installed ( https://developer.mthreads.com/musa/musa-sdk ).
# HIP: this provides GPU acceleration on HIP-supported AMD GPUs. Make sure to have ROCm installed. You can download it from your Linux distro's package manager or from here: ROCm Quick Start (Linux): https://rocm.docs.amd.com/projects/install-on-linux/en/latest/tutorial/quick-start.html#rocm-install-quick
# Vulkan: First, follow the official LunarG instructions for the installation and setup of the Vulkan SDK in the Getting Started with the Linux Tarball Vulkan SDK guide. ( https://vulkan.lunarg.com/doc/sdk/latest/linux/getting_started.html )
# CANN: this provides NPU acceleration using the AI cores of your Ascend NPU. And CANN is a hierarchical APIs to help you to quickly build AI applications and service based on Ascend NPU. ( https://www.hiascend.com/en/software/cann )
# Arm® KleidiAI™: KleidiAI is a library of optimized microkernels for AI workloads, specifically designed for Arm CPUs. These microkernels enhance performance and can be enabled for use by the CPU backend.
# OpenCL: This provides GPU acceleration through OpenCL on recent Adreno GPU. More information about OpenCL backend can be found in OPENCL.md for more information. ( https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENCL.md )
# WebGPU: The WebGPU backend relies on Dawn ( https://dawn.googlesource.com/dawn ). Follow the instructions here ( https://dawn.googlesource.com/dawn/+/refs/heads/main/docs/quickstart-cmake.md ) to install Dawn locally so that llama.cpp can find it using CMake. The currrent implementation is up-to-date with Dawn commit bed1a61. 
# TBD: IBM Z & LinuxONE

# CPU_FLAGS_x86_fma doesn't exist, thus place everything here.
IUSE="
systemd
utils
static
lto
test
examples
disable-arm-neon
dynamic-backends
curl
hbm
android
msvc
+accelerate
blas
blis
+llamafile
cann
musa
cuda
cuda-force-mmq
cuda-force-cublas
+cuda-unified-memory
cuda-f16
cuda-no-peer-copy
cuda-no-vmm
cuda-fa-all-quants
+cuda-graphs
hip
hip-graphs
+hip-no-vmm
hip-uma
vulkan
vulkan-check-results
vulkan-debug
vulkan-memory-debug
vulkan-shader-debug-info
vulkan-perf
vulkan-validate
vulkan-run-tests
kompute
+openmp
rpc
opencl
opencl-profiling
+opencl-embed-kernels
+opencl-use-adreno-kernels
metal
metal-use-bf16
metal-ndebug
metal-shader-debug
+metal-embed-library
+cpu
webgpu
cpu-native
cpu-all-variants
cpu_flags_x86_avx
cpu_flags_x86_avx_vnni
cpu_flags_x86_avx2
cpu_flags_x86_avx512
cpu_flags_x86_avx512_vbmi
cpu_flags_x86_avx512_vnni
cpu_flags_x86_avx512_bf16
cpu_flags_x86_fma
cpu_flags_x86_f16c
cpu_flags_x86_amx_tile
cpu_flags_x86_amx_int8
cpu_flags_x86_amx_bf16
cpu_flags_x86_sse
cpu_flags_x86_sse2
cpu_flags_x86_sse3
cpu_flags_x86_sse4
cpu_flags_x86_sse4a
cpu_flags_x86_sse41
cpu_flags_x86_sse42
cpu_flags_x86_ssse3
kleidiai
cpu_flags_loong_lasx
cpu_flags_loong_lsx
cpu_flags_riscv_rvv
"

# since this is too hard to do right now
# "sycl
# sycl-f16
# sycl-target-nvidia
# sycl-target-amdgpu
# sycl-target-intelgpu
# sycl-via-openapi
# sycl-via-opemkl
# "

# in MSVC F16C and FMA is implied with AVX2/AVX512
# MSVC does not seem to support AMX
# android stuff added according to their docs.
# a lot of !flag ( !subflags ) statements placed for binpkg correctness

REQUIRED_USE="
	?? ( python_single_target_python3_11 python_single_target_python3_12 )
	|| ( cpu cuda cuda-f16 hip vulkan cann musa kompute opencl metal webgpu kleidiai )
	test? ( curl )
	vulkan-run-tests? ( test )
	blis? ( blas )
	cpu-native? ( cpu )
	cpu-all-variants? ( cpu )
	cuda? ( cpu )
	android? (
		!llamafile
		!openmp
	)
	msvc? (
		!cpu_flags_x86_fma
		!cpu_flags_x86_f16c
		!cpu_flags_x86_amx_tile
		!cpu_flags_x86_amx_int8
		!cpu_flags_x86_amx_bf16
	)
	!cuda? (
		!cuda-force-mmq
		!cuda-force-cublas
		!cuda-unified-memory
		!cuda-f16
		!cuda-no-peer-copy
		!cuda-no-vmm
		!cuda-fa-all-quants
		!cuda-graphs
	)
	!hip? (
		!hip-graphs
		!hip-no-vmm
		!hip-uma
	)
	!vulkan? (
		!vulkan-check-results
		!vulkan-debug
		!vulkan-memory-debug
		!vulkan-shader-debug-info
		!vulkan-perf
		!vulkan-validate
		!vulkan-run-tests
	)
	!opencl? (
		!opencl-profiling
		!opencl-embed-kernels
		!opencl-use-adreno-kernels
	)
	!cpu? (
		!cpu_flags_x86_avx
		!cpu_flags_x86_avx_vnni
		!cpu_flags_x86_avx2
		!cpu_flags_x86_avx512
		!cpu_flags_x86_avx512_vbmi
		!cpu_flags_x86_avx512_vnni
		!cpu_flags_x86_avx512_bf16
		!cpu_flags_x86_fma
		!cpu_flags_x86_f16c
		!cpu_flags_x86_amx_tile
		!cpu_flags_x86_amx_int8
		!cpu_flags_x86_amx_bf16
		!cpu_flags_x86_sse
		!cpu_flags_x86_sse2
		!cpu_flags_x86_sse3
		!cpu_flags_x86_sse4
		!cpu_flags_x86_sse4a
		!cpu_flags_x86_sse41
		!cpu_flags_x86_sse42
		!cpu_flags_x86_ssse3

		!cpu_flags_loong_lasx
		!cpu_flags_loong_lsx

		!cpu_flags_riscv_rvv
	)
	dynamic-backends? ( !cpu-native )
"
#	cuda-unified-memory? ( || ( cuda cuda-f16 ) )
#	cpu? ( || ( cpu-native cpu-all-variants ) )


DEPEND="
	blas? ( virtual/blas )
	cuda? ( dev-util/nvidia-cuda-toolkit )
	blis? ( sci-libs/blis )
	opencl? ( virtual/opencl )
	kleidiai? ( dev-cpp/kleidiai )
	dev-vcs/git
	net-misc/curl
	net-misc/wget
	utils? ( dev-python/virtualenv )
    app-admin/sudo
"
# since this is too hard right now.
# https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/SYCL.md
# To be done a bit later.
# 	sycl-target-nvidia? ( dev-util/nvidia-cuda-toolkit )
# 	sycl-target-amdgpu? ( dev-util/nvidia-cuda-toolkit )
# 	sycl-target-intelgpu? ( dev-util/nvidia-cuda-toolkit )
# "

#DEPEND="\
#    ${RDEPEND}
#    dev-vcs/git
#    net-misc/curl
#    net-misc/wget
#    utils? ( dev-python/virtualenv )
#    openblas? ( virtual/blas sci-libs/openblas[eselect-ldso] sci-libs/lapack[eselect-ldso,lapacke] virtual/lapacke[eselect-ldso] virtual/cblas )
#    blis? ( sci-libs/blis )
#    onemkl? ( sci-libs/mkl )
#    sycl_oneapi? ( sci-libs/mkl )
#    sycl_oneapi_16? ( sci-libs/mkl )
#    sycl_nvidia? ( sci-ml/oneDNN )
#    sycl_nvidia_16? ( sci-ml/oneDNN )
#    sycl_amd? ( dev-libs/roct-thunk-interface dev-libs/rocr-runtime )
#    cuda? ( dev-util/nvidia-cuda-toolkit )
#    hip? (  dev-util/hip )
#    vulkan? ( media-libs/vulkan-loader )
#    opencl? ( virtual/opencl )
#"


BEPEND="virtual/pkgconfig
    dev-util/ccache"

RDEPEND="
	acct-user/genai
	acct-group/genai
	blas? ( virtual/blas )
	cuda? ( dev-util/nvidia-cuda-toolkit )
	blis? ( sci-libs/blis )
	opencl? ( virtual/opencl )
"

BDEPEND="
"

RESTRICT="!test? ( test ) test? ( userpriv )"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/opt/llama-cpp"
CONFIG_DIR="/etc/llama-cpp"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="llama-cpp"
    S="${WORKDIR}/llama-cpp-${MY_PV}"
else
	MY_PV="b${PV#0.}"
	
	SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/${MY_PV}.tar.gz -> llama.cpp-${MY_PV}.tar.gz"
	
	S="${WORKDIR}/llama.cpp-${MY_PV}"
fi

src_prepare() {
	if use cuda; then
		cuda_src_prepare
	fi
	gpu_arch=""
	if use cuda; then
		gpu_arch="cuda"
	fi
	if use cuda-f16; then
		gpu_arch="cuda-f16"
	fi
	if use hip; then
		gpu_arch="hip"
	fi
	if use vulkan; then
		gpu_arch="vulkan"
	fi
	if use cann; then
		gpu_arch="cann"
	fi
	if use musa; then
		gpu_arch="musa"
	fi
	if use kompute; then
		gpu_arch="kompute"
	fi
	if use opencl; then
		gpu_arch="opencl"
	fi
	if use metal; then
		gpu_arch="metal"
	fi
	if use webgpu; then
		gpu_arch="webgpu"
	fi
	if use kleidiai; then
		gpu_arch="kleidiai"
	fi
	if use cpu; then
		cpu_ver_selected="no"
		if use cpu-native; then
			cpu_ver_selected="yes"
		fi
		if use cpu-all-variants; then
			cpu_ver_selected="yes"
		fi
		if [ "${cpu_ver_selected}" == "no" ]; then
			if [[ -z "${gpu_arch}" ]]; then
				eerror "!!! You have selected just CPU but did not specify if that should be native or all variants. Please select use \"native\" or \"cpu-all-variants\"."
				exit 1
			fi
		fi
	fi
	cmake_src_prepare
}

src_configure() {
	die() { echo "$*" 1>&2 ; exit 1; }
	if use hip; then
		HIPCC=$(hipconfig -l)/clang
		HIPCXX=$(hipconfig -l)/clang++
		# export DEVICE_LIB_PATH=${EPREFIX}/usr/lib/amdgcn/bitcode # not sure what to do with that
		HIP_PATH=$(hipconfig -R)
	fi

	local mycmakeargs=(
		-DGGML_LTO=$(usex lto ON OFF)

		# add these via user's /etc/portage/make.conf as i.e.`-fsanitize=address`
		-DLLAMA_SANITIZE_THREAD=OFF
		-DLLAMA_SANITIZE_ADDRESS=OFF
		-DLLAMA_SANITIZE_UNDEFINED=OFF

		-DLLAMA_CURL=$(usex curl ON OFF)

		-DLLAMA_BUILD_TESTS=$(usex test ON OFF)
		-DLLAMA_BUILD_EXAMPLES=$(usex examples ON OFF)
		#-DLLAMA_BUILD_SERVER=$(usex server ON OFF)
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_COMMON=ON
		# -DLLAMA_BUILD_SERVER=OFF # why
		# -DCMAKE_SKIP_BUILD_RPATH=ON # why?
		-DBUILD_NUMBER="${MY_PV}"
		# -DCMAKE_INSTALL_PREFIX=${EPREFIX}/opt/${PN} # why would you need that?
		# -DCMAKE_CUDA_ARCHITECTURES="75" # I guess this should be set by user.

		-DBUILD_SHARED_LIBS=$(usex static OFF ON)

		-DGGML_CPU=$(usex cpu ON OFF)

		-DGGML_BACKEND_DL=$(usex dynamic-backends ON OFF)
		-DGGML_CPU_ALL_VARIANTS=$(usex cpu-all-variants ON OFF)

		-DGGML_NATIVE=$(usex cpu-native ON OFF)

		-DGGML_CPU_AARCH64=$(usex arm64 ON OFF)
		-DGGML_CPU_HBM=$(usex hbm ON OFF)
		-DGGML_CPU_KLEIDIAI=$(usex kleidiai ON OFF)
		-DGGML_AVX=$(usex cpu_flags_x86_avx ON OFF)
		-DGGML_AVX_VNNI=$(usex cpu_flags_x86_avx_vnni ON OFF)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2 ON OFF)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512 ON OFF)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512_vbmi ON OFF)
		-DGGML_AVX512_VNNI=$(usex cpu_flags_x86_avx512_vnni ON OFF)
		-DGGML_AVX512_BF16=$(usex cpu_flags_x86_avx512_bf16 ON OFF)
		-DGGML_FMA=$(usex cpu_flags_x86_fma ON OFF)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c ON OFF)
		-DGGML_AMX_TILE=$(usex cpu_flags_x86_amx_tile ON OFF)
		-DGGML_AMX_INT8=$(usex cpu_flags_x86_amx_int8 ON OFF)
		-DGGML_AMX_BF16=$(usex cpu_flags_x86_amx_bf16 ON OFF)
		-DGGML_SSE=$(usex cpu_flags_x86_sse ON OFF)
		-DGGML_SSE2=$(usex cpu_flags_x86_sse2 ON OFF)
		-DGGML_SSE3=$(usex cpu_flags_x86_sse3 ON OFF)
		-DGGML_SSE4=$(usex cpu_flags_x86_sse4 ON OFF)
		-DGGML_SSE4A=$(usex cpu_flags_x86_sse4a ON OFF)
		-DGGML_SSE41=$(usex cpu_flags_x86_sse41 ON OFF)
		-DGGML_SSE42=$(usex cpu_flags_x86_sse42 ON OFF)
		-DGGML_SSSE3=$(usex cpu_flags_x86_ssse3 ON OFF)
		-DGGML_LASX=$(usex cpu_flags_loong_lasx ON OFF)
		-DGGML_LSX=$(usex cpu_flags_loong_lsx ON OFF)
		-DGGML_RVV=$(usex cpu_flags_riscv_rvv ON OFF)

		-DGGML_ACCELERATE=$(usex accelerate ON OFF)

		-DGGML_BLAS=$(usex blas ON OFF)

		-DGGML_CANN=$(usex cann ON OFF)

		-DGGML_LLAMAFILE=$(usex llamafile ON OFF)

		-DGGML_MUSA=$(usex musa ON OFF)

		-DGGML_CUDA=$(usex cuda ON OFF)
		-DGGML_CUDA_FORCE_MMQ=$(usex cuda-force-mmq ON OFF)
		-DGGML_CUDA_FORCE_CUBLAS=$(usex cuda-force-cublas ON OFF)
		-DGGML_CUDA_F16=$(usex cuda-f16 ON OFF)
		-DGGML_CUDA_NO_PEER_COPY=$(usex cuda-no-peer-copy ON OFF)
		-DGGML_CUDA_NO_VMM=$(usex cuda-no-vmm ON OFF)
		-DGGML_CUDA_FA_ALL_QUANTS=$(usex cuda-fa-all-quants ON OFF)
		-DGGML_CUDA_GRAPHS=$(usex cuda-graphs ON OFF)
		# CPU+GPU Unified Memory
		-DGGML_CUDA_ENABLE_UNIFIED_MEMORY=$(usex cuda-unified-memory 1 0)

		-DGGML_HIP=$(usex hip ON OFF)
		-DGGML_HIP_GRAPHS=$(usex hip-graphs ON OFF)
		-DGGML_HIP_NO_VMM=$(usex hip-no-vmm ON OFF)
		-DGGML_HIP_UMA=$(usex hip-uma ON OFF)

		-DGGML_VULKAN=$(usex vulkan ON OFF)
		-DGGML_VULKAN_CHECK_RESULTS=$(usex vulkan-check-results ON OFF)
		-DGGML_VULKAN_DEBUG=$(usex vulkan-debug ON OFF)
		-DGGML_VULKAN_MEMORY_DEBUG=$(usex vulkan-memory-debug ON OFF)
		-DGGML_VULKAN_SHADER_DEBUG_INFO=$(usex vulkan-shader-debug-info ON OFF)
		-DGGML_VULKAN_PERF=$(usex vulkan-perf ON OFF)
		-DGGML_VULKAN_VALIDATE=$(usex vulkan-validate ON OFF)
		-DGGML_VULKAN_RUN_TESTS=$(usex vulkan-run-tests ON OFF)

		-DGGML_KOMPUTE=$(usex kompute ON OFF)

		-DGGML_METAL=$(usex metal ON OFF)
		-DGGML_METAL_USE_BF16=$(usex metal-use-bf16 ON OFF)
		-DGGML_METAL_NDEBUG=$(usex metal-ndebug ON OFF)
		-DGGML_METAL_SHADER_DEBUG=$(usex metal-shader-debug ON OFF)
		-DGGML_METAL_EMBED_LIBRARY=$(usex metal-embed-library ON OFF)

		-DGGML_OPENMP=$(usex openmp ON OFF)

		-DGGML_RPC=$(usex rpc ON OFF)

		-DGGML_SYCL=OFF
		# -DGGML_SYCL=$(usex sycl ON OFF)
		# -DGGML_SYCL_F16=$(usex sycl-f16 ON OFF)

		-DGGML_OPENCL=$(usex opencl ON OFF)
		-DGGML_OPENCL_PROFILING=$(usex opencl-profiling ON OFF)
		-DGGML_OPENCL_EMBED_KERNELS=$(usex opencl-embed-kernels ON OFF)
		-DGGML_OPENCL_USE_ADRENO_KERNELS=$(usex opencl-use-adreno-kernels ON OFF)

		# -DGGML_BUILD_TESTS=$(usex test ON OFF) # broken option
		# -DGGML_BUILD_EXAMPLES=$(usex examples ON OFF) # broken option

		# Gentoo users enable ccache via e.g. FEATURES=ccache or
		# other means. We don't want the build system to enable it for us.
		-DGGML_CCACHE=OFF

		# defaults aren't so good
		--log-level=DEBUG
		-DFETCHCONTENT_QUIET=OFF
	)

	if use webgpu; then
		mycmakeargs+=( -DGGML_WEBGPU=ON )
	fi

	if use blis; then
		mycmakeargs+=( -DGGML_BLAD_VENDOR=FLAME )
	fi

	if use hip; then
		mycmakeargs+=( -DAMDGPU_TARGETS=$(get_amdgpu_flags) )
	fi

	#sed -i "s,list(APPEND CXX_FLAGS -Wmissing-declarations -Wmissing-noreturn),list(APPEND CXX_FLAGS -Wmissing-declarations -Wmissing-noreturn -Wno-deprecated-gpu-targets)," cmake/common.cmake || die "Couln't fix the nvcc."
	sed -i "/set(CUDA_CXX_FLAGS \"\")/a list(APPEND CMAKE_CUDA_FLAGS -Wno-deprecated-gpu-targets)" ggml/src/ggml-cuda/CMakeLists.txt || die "Couln't fix the nvcc."
	use_cuda="no"
	if use cuda; then
		use_cuda="yes"
	fi
	if use cuda-f16; then
		use_cuda="yes"
	fi
	if use disable-arm-neon; then
		mycmakeargs+=( -DCMAKE_CUDA_FLAGS="-U__ARM_NEON -U__ARM_NEON__" )
	fi
	if [[ "${use_cuda}" == "yes" ]]; then
		#mycmakeargs+=( -DCMAKE_CUDA_FLAGS="-D__STRICT_ANSI__" )
		nvcc_version=$(nvcc --version | grep release | awk '{print substr($5, 1, length($5)-1)}')
		nvidia_smi_version=$(nvidia-smi -q | grep CUDA | awk '{print $4}')
		if [[ "${nvcc_version}" != "${nvidia_smi_version}" ]] && [[ ! -z "${nvcc_version}" ]] && [[ ! -z "${nvidia_smi_version}" ]]; then
			ewarn "Warning!!! We have detected that nvcc's cuda version (\"${nvcc_version}\") doesn't seem to be the same as nvidia-smi's cuda version(\"${nvidia_smi_version}\"). Please consider reinstalling dev-util/nvidia-cuda-toolkit in case of compilation errors."
		fi
	fi

	cmake-multilib_src_configure
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}/models"
    mkdir -p "${D}${INSTALL_DIR}/gguf-py"
    mkdir -p "${D}${CONFIG_DIR}"
    cd "${S}"
    if use utils; then
        elog "Also creating utils."
        cp -f "${FILESDIR}/llama_convert_hf_to_gguf" "${D}${INSTALL_DIR}/"
        cp -f "${FILESDIR}/llama_convert_hf_to_gguf_update" "${D}${INSTALL_DIR}/"
        cp -f "${FILESDIR}/llama_convert_llama_ggml_to_gguf" "${D}${INSTALL_DIR}/"
        cp -f "${FILESDIR}/llama_convert_lora_to_gguf" "${D}${INSTALL_DIR}/"
        dosbin "${D}${INSTALL_DIR}/llama_convert_hf_to_gguf"
        dosbin "${D}${INSTALL_DIR}/llama_convert_hf_to_gguf_update"
        dosbin "${D}${INSTALL_DIR}/llama_convert_llama_ggml_to_gguf"
        dosbin "${D}${INSTALL_DIR}/llama_convert_lora_to_gguf"
        cp -f "${S}/convert_hf_to_gguf.py" "${D}${INSTALL_DIR}/convert_hf_to_gguf.py"
        cp -f "${S}/convert_hf_to_gguf_update.py" "${D}${INSTALL_DIR}/convert_hf_to_gguf_update.py"
        cp -f "${S}/convert_llama_ggml_to_gguf.py" "${D}${INSTALL_DIR}/convert_llama_ggml_to_gguf.py"
        cp -f "${S}/convert_lora_to_gguf.py" "${D}${INSTALL_DIR}/convert_lora_to_gguf.py"
        cp -f "${S}/requirements.txt" "${D}${INSTALL_DIR}/requirements.txt"
        mkdir -p "${D}${INSTALL_DIR}/requirements"
        mkdir -p "${D}${INSTALL_DIR}/tools/mtmd"
        mkdir -p "${D}${INSTALL_DIR}/tools/server/bench"
        mkdir -p "${D}${INSTALL_DIR}/tools/server/tests"
        cp -rf ${S}/requirements/* "${D}${INSTALL_DIR}/requirements/"
        cp -f "${S}/tools/mtmd/requirements.txt" "${D}${INSTALL_DIR}/tools/mtmd/"
        cp -f "${S}/tools/server/bench/requirements.txt" "${D}${INSTALL_DIR}/tools/server/bench/"
        cp -f "${S}/tools/server/tests/requirements.txt" "${D}${INSTALL_DIR}/tools/server/tests/"
        cp -rf "${S}/gguf-py" "${D}${INSTALL_DIR}/"
    fi
    chown -R genai:genai "${D}${INSTALL_DIR}"
    cd "${D}"
    keepdir "${INSTALL_DIR}/models"
    einfo "Example configurations will be stored here: \"${CONFIG_DIR}\"."
    insinto "${CONFIG_DIR}"
    doins "${FILESDIR}/env.conf.example"
    if use systemd; then
        elog "Created Systemd service \"llama-cpp.service\""
        systemd_newunit "${FILESDIR}/llama-cpp${APPNDX3}.service" llama-cpp.service
    fi
    default
    cmake-multilib_src_install
}

pkg_postinst() {
    die() { eerror "$*" 1>&2 ; exit 1; }
    cd "${EROOT}${INSTALL_DIR}"
    python_xq="python"
    if use python_single_target_python3_11; then
	python_xq="python3.11"
    fi
    if use python_single_target_python3_12; then
	python_xq="python3.12"
    fi
    if use utils; then
        sed -i "s/python/${python_xq}/" "${EROOT}${INSTALL_DIR}/llama_convert_hf_to_gguf"
        sed -i "s/python/${python_xq}/" "${EROOT}${INSTALL_DIR}/llama_convert_hf_to_gguf_update"
        sed -i "s/python/${python_xq}/" "${EROOT}${INSTALL_DIR}/llama_convert_llama_ggml_to_gguf"
        sed -i "s/python/${python_xq}/" "${EROOT}${INSTALL_DIR}/llama_convert_lora_to_gguf"
        sudo -u genai bash -c "$python_xq -m venv ./venv;source venv/bin/activate;pip install --upgrade pip;pip install -r requirements.txt;pip install --upgrade transformers;deactivate"
    fi
}

pkg_prerm() {
    if use utils; then
        einfo "Removing virtual environment."
        [[ -d "${EROOT}${INSTALL_DIR}/venv" ]] && rm -rf "${EROOT}${INSTALL_DIR}/venv"
        einfo "Removing python tools."
        rm -rf "${EROOT}${INSTALL_DIR}/gguf-py"
    fi
}
