#!/bin/bash

die() { echo "$*" 1>&2 ; exit 1; }
CONFIG_FILE="/etc/comfyui/env.conf"
#export CUDA_VISIBLE_DEVICES=-1
export PATH="${PATH}:/opt/cuda/bin/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/cuda/lib64/"
export PKG_CONFIG_PATH="/opt/cuda/pkgconfig"
export CUDA_HOME="/opt/cuda/"

cd /opt/comfyui/

if [ ! -f /opt/comfyui/package_version.txt ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat /opt/comfyui/package_version.txt`
fi

FIRST_RUN="0"

if [ ! -f /opt/comfyui/configured ]; then
    FIRST_RUN="1"
else
    if [ ! -f /opt/comfyui/package_version.txt ]; then
        PACKAGEVERSIONTEST=9999
    else
        PACKAGEVERSIONTEST=`cat /opt/comfyui/configured`
    fi
    if [[ "${PACKAGEVERSIONTEST}" != "${PACKAGEVERSION}" ]]; then
        FIRST_RUN="1"
    fi
fi

if [[ "${FIRST_RUN}" == "1" ]]; then
    cat /opt/comfyui/package_version.txt > /opt/comfyui/configured
    touch /opt/comfyui/configured
fi

RUN_STR=""

if [ ! -e "${CONFIG_FILE}" ]; then
    RUN_STR="${RUN_STR}"
else
    COMFYUI_LAUNCH_MODE="-"
    COMFYUI_HOST="-"
    COMFYUI_PORT="-"
    COMFYUI_VERBOSE_LEVEL="-"
    COMFYUI_TLS_KEYFILE="-"
    COMFYUI_TLS_CERTFILE="-"
    COMFYUI_ENABLE_CORS_HEADER="-"
    COMFYUI_MAX_UPLOAD_SIZE="-"
    COMFYUI_BASE_DIRECTORY="-"
    COMFYUI_EXTRA_MODELS_PATHS_CONFIG="-"
    COMFYUI_OUTPUT_DIRECTORY="-"
    COMFYUI_TEMP_DIRECTORY="-"
    COMFYUI_INPUT_DIRECTORY="-"
    COMFYUI_CUDA_DEVICE="-"
    COMFYUI_DEFAULT_DEVICE="-"
    COMFYUI_CUDA_MALLOC="-"
    COMFYUI_FORCE_FP32="-"
    COMFYUI_FORCE_FP16="-"
    COMFYUI_FORCE_FP64_UNET="-"
    COMFYUI_FORCE_FP32_UNET="-"
    COMFYUI_FORCE_FP16_UNET="-"
    COMFYUI_FORCE_FP8_E4M3FN_UNET="-"
    COMFYUI_FORCE_FP8_E5M3_UNET="-"
    COMFYUI_FORCE_FP8_E8M0FNU_UNET="-"
    COMFYUI_FORCE_BF16_UNET="-"
    COMFYUI_FORCE_FP32_VAE="-"
    COMFYUI_FORCE_FP16_VAE="-"
    COMFYUI_FORCE_BF16_VAE="-"
    COMFYUI_FORCE_CPU_VAE="-"
    COMFYUI_FP32_TEXT_ENC="-"
    COMFYUI_FP16_TEXT_ENC="-"
    COMFYUI_FP8_E4M3FN_TEXT_ENC="-"
    COMFYUI_FP8_E5M2_TEXT_ENC="-"
    COMFYUI_BF16_TEXT_ENC="-"
    COMFYUI_FORCE_CHANNELS_LAST="-"
    COMFYUI_DIRECTML="-"
    COMFYUI_ONEAPI_DEVICE_SELECTOR="-"
    COMFYUI_DISABLE_IPEX_OPTIMIZE="-"
    COMFYUI_SUPPORTS_FP8_COMPUTE="-"
    COMFYUI_PREVIEW_METHOD="-"
    COMFYUI_PREVIEW_SIZE="-"
    COMFYUI_CACHE_CLASSIC="-"
    COMFYUI_CACHE_NONE="-"
    COMFYUI_CACHE_LRU="-"
    COMFYUI_USE_SPLIT_CROSS_ATTENTION="-"
    COMFYUI_USE_QUAD_CROSS_ATTENTION="-"
    COMFYUI_USE_PYTORCH_CROSS_ATTENTION="-"
    COMFYUI_USE_SAGE_ATTENTION="-"
    COMFYUI_USE_FLASH_ATTENTION="-"
    COMFYUI_FORCE_UPCAST_ATTENTION="-"
    COMFYUI_DONT_UPCAST_ATTENTION="-"
    COMFYUI_DISABLE_XFORMERS="-"
    COMFYUI_GPU_ONLY="-"
    COMFYUI_HIGHVRAM="-"
    COMFYUI_NORMALVRAM="-"
    COMFYUI_LOWVRAM="-"
    COMFYUI_NOVRAM="-"
    COMFYUI_CPU_ONLY="-"
    COMFYUI_RESERVE_VRAM="-"
    COMFYUI_ASYNC_OFFLOAD="-"
    COMFYUI_FORCE_NON_BLOCKING="-"
    COMFYUI_DEFAULT_HASHING_FUNCTION="-"
    COMFYUI_DISABLE_SMART_MEMORY="-"
    COMFYUI_DETERMINISTIC="-"
    COMFYUI_FAST="-"
    COMFYUI_MMAP_TORCH_FILES="-"
    COMFYUI_DISABLE_MMAP="-"
    COMFYUI_DONT_PRINT_SERVER="-"
    COMFYUI_QUICK_TEST_FOR_CI="-"
    COMFYUI_DISABLE_METADATA="-"
    COMFYUI_DISABLE_ALL_CUSTOM_NODES="-"
    COMFYUI_WHITELIST_CUSTOM_NODES="-"
    COMFYUI_DISABLE_API_NODES="-"
    COMFYUI_MULTI_USER="-"
    COMFYUI_LOG_STDOUT="-"
    COMFYUI_FRONTEND_ROOT="-"
    COMFYUI_USER_DIRECTORY="-"
    COMFYUI_ENABLE_COMPRESS_RESPONSE_BODY="-"
    COMFYUI_COMFY_API_BASE="-"
    COMFYUI_DATABASE_URL="-"
    COMFYUI_EXTRA="-"
    
    source "${CONFIG_FILE}"
    #if [ "${COMFYUI_LAUNCH_MODE}" != "-" ]; then
    #    RUN_STR="${RUN_STR} --auto-launch"
    #else
    #    RUN_STR="${RUN_STR} --disable-auto-launch"
    #fi
    if [ "${COMFYUI_HOST}" != "-" ]; then
        RUN_STR="${RUN_STR} --listen ${COMFYUI_HOST}"
    fi
    if [ "${COMFYUI_PORT}" != "-" ]; then
        RUN_STR="${RUN_STR} --port ${COMFYUI_PORT}"
    fi
    if [ "${COMFYUI_VERBOSE_LEVEL}" != "-" ]; then
        RUN_STR="${RUN_STR} --verbose ${COMFYUI_VERBOSE_LEVEL}"
    fi
    if [ "${COMFYUI_TLS_KEYFILE}" != "-" ]; then
        RUN_STR="${RUN_STR} --tls-keyfile \"${COMFYUI_TLS_KEYFILE}\""
    fi
    if [ "${COMFYUI_TLS_CERTFILE}" != "-" ]; then
        RUN_STR="${RUN_STR} --tls-certfile \"${COMFYUI_TLS_CERTFILE}\""
    fi
    if [ "${COMFYUI_ENABLE_CORS_HEADER}" != "-" ]; then
        RUN_STR="${RUN_STR} --tls-enable-cors-header \"${COMFYUI_ENABLE_CORS_HEADER}\""
    fi
    if [ "${COMFYUI_MAX_UPLOAD_SIZE}" != "-" ]; then
        RUN_STR="${RUN_STR} --max-upload-size ${COMFYUI_MAX_UPLOAD_SIZE}"
    fi
    if [ "${COMFYUI_BASE_DIRECTORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --base-directory \"${COMFYUI_BASE_DIRECTORY}\""
    fi
    if [ "${COMFYUI_EXTRA_MODELS_PATHS_CONFIG}" != "-" ]; then
        RUN_STR="${RUN_STR} --extra-model-paths-config \"${COMFYUI_EXTRA_MODELS_PATHS_CONFIG}\""
    fi
    if [ "${COMFYUI_OUTPUT_DIRECTORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --output-directory \"${COMFYUI_OUTPUT_DIRECTORY}\""
    fi
    if [ "${COMFYUI_TEMP_DIRECTORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --temp-directory \"${COMFYUI_TEMP_DIRECTORY}\""
    fi
    if [ "${COMFYUI_INPUT_DIRECTORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --input-directory \"${COMFYUI_INPUT_DIRECTORY}\""
    fi
    if [ "${COMFYUI_CUDA_DEVICE}" != "-" ]; then
        RUN_STR="${RUN_STR} --cuda-device ${COMFYUI_CUDA_DEVICE}"
    fi
    if [ "${COMFYUI_DEFAULT_DEVICE}" != "-" ]; then
        RUN_STR="${RUN_STR} --default-device ${COMFYUI_DEFAULT_DEVICE}"
    fi
    if [ "${COMFYUI_CUDA_MALLOC}" != "-" ]; then
        if [ "${COMFYUI_CUDA_MALLOC}" != "yes" ]; then
            RUN_STR="${RUN_STR} --disable-cuda-malloc"
        else
            RUN_STR="${RUN_STR} --cuda-malloc"
        fi
    fi
    if [ "${COMFYUI_FORCE_FP32}" != "-" ]; then
        RUN_STR="${RUN_STR} --force-fp32"
    fi
    if [ "${COMFYUI_FORCE_FP16}" != "-" ]; then
        RUN_STR="${RUN_STR} --force-fp16"
    fi
    if [ "${COMFYUI_FORCE_FP64_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp64-unet"
    fi
    if [ "${COMFYUI_FORCE_FP32_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp32-unet"
    fi
    if [ "${COMFYUI_FORCE_FP16_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp16-unet"
    fi
    if [ "${COMFYUI_FORCE_FP8_E4M3FN_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp8_e4m3fn-unet"
    fi
    if [ "${COMFYUI_FORCE_FP8_E5M3_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp8_e5m2-unet"
    fi
    if [ "${COMFYUI_FORCE_FP8_E8M0FNU_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp8_e8m0fnu-unet"
    fi
    if [ "${COMFYUI_FORCE_BF16_UNET}" != "-" ]; then
        RUN_STR="${RUN_STR} --bf16-unet"
    fi
    if [ "${COMFYUI_FORCE_FP32_VAE}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp32-vae"
    fi
    if [ "${COMFYUI_FORCE_FP16_VAE}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp16-vae"
    fi
    if [ "${COMFYUI_FORCE_BF16_VAE}" != "-" ]; then
        RUN_STR="${RUN_STR} --bf16-vae"
    fi
    if [ "${COMFYUI_FORCE_CPU_VAE}" != "-" ]; then
        RUN_STR="${RUN_STR} --cpu-vae"
    fi
    if [ "${COMFYUI_FP32_TEXT_ENC}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp32-text-enc"
    fi
    if [ "${COMFYUI_FP16_TEXT_ENC}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp16-text-enc"
    fi
    if [ "${COMFYUI_FP8_E4M3FN_TEXT_ENC}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp8_e4m3fn-text-enc"
    fi
    if [ "${COMFYUI_FP8_E5M2_TEXT_ENC}" != "-" ]; then
        RUN_STR="${RUN_STR} --fp8_e5m2-text-enc"
    fi
    if [ "${COMFYUI_BF16_TEXT_ENC}" != "-" ]; then
        RUN_STR="${RUN_STR} --bf16-text-enc"
    fi
    if [ "${COMFYUI_FORCE_CHANNELS_LAST}" != "-" ]; then
        RUN_STR="${RUN_STR} --force-channels-last"
    fi
    if [ "${COMFYUI_DIRECTML}" != "-" ]; then
        RUN_STR="${RUN_STR} --directml \"${COMFYUI_DIRECTML}\""
    fi
    if [ "${COMFYUI_ONEAPI_DEVICE_SELECTOR}" != "-" ]; then
        RUN_STR="${RUN_STR} --oneapi-device-selector \"${COMFYUI_ONEAPI_DEVICE_SELECTOR}\""
    fi
    if [ "${COMFYUI_DISABLE_IPEX_OPTIMIZE}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-ipex-optimize"
    fi
    if [ "${COMFYUI_SUPPORTS_FP8_COMPUTE}" != "-" ]; then
        RUN_STR="${RUN_STR} --supports-fp8-compute"
    fi
    if [ "${COMFYUI_PREVIEW_METHOD}" != "-" ]; then
        RUN_STR="${RUN_STR} --preview-method ${COMFYUI_PREVIEW_METHOD}"
    fi
    if [ "${COMFYUI_PREVIEW_SIZE}" != "-" ]; then
        RUN_STR="${RUN_STR} --preview-size ${COMFYUI_PREVIEW_SIZE}"
    fi
    if [ "${COMFYUI_CACHE_CLASSIC}" != "-" ]; then
        RUN_STR="${RUN_STR} --cache-classic"
    fi
    if [ "${COMFYUI_CACHE_NONE}" != "-" ]; then
        RUN_STR="${RUN_STR} --cache-none"
    fi
    if [ "${COMFYUI_CACHE_LRU}" != "-" ]; then
        RUN_STR="${RUN_STR} --cache-lru ${COMFYUI_CACHE_LRU}"
    fi
    if [ "${COMFYUI_USE_SPLIT_CROSS_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --use-split-cross-attention"
    fi
    if [ "${COMFYUI_USE_QUAD_CROSS_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --use-quad-cross-attention"
    fi
    if [ "${COMFYUI_USE_PYTORCH_CROSS_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --use-pytorch-cross-attention"
    fi
    if [ "${COMFYUI_USE_SAGE_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --use-sage-attention"
    fi
    if [ "${COMFYUI_USE_FLASH_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --use-flash-attention"
    fi
    if [ "${COMFYUI_FORCE_UPCAST_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --force-upcast-attention"
    fi
    if [ "${COMFYUI_DONT_UPCAST_ATTENTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --dont-upcast-attention"
    fi
    if [ "${COMFYUI_DISABLE_XFORMERS}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-xformers"
    fi
    if [ "${COMFYUI_GPU_ONLY}" != "-" ]; then
        RUN_STR="${RUN_STR} --gpu-only"
    fi
    if [ "${COMFYUI_HIGHVRAM}" != "-" ]; then
        RUN_STR="${RUN_STR} --highvram"
    fi
    if [ "${COMFYUI_NORMALVRAM}" != "-" ]; then
        RUN_STR="${RUN_STR} --normalvram"
    fi
    if [ "${COMFYUI_LOWVRAM}" != "-" ]; then
        RUN_STR="${RUN_STR} --lowvram"
    fi
    if [ "${COMFYUI_NOVRAM}" != "-" ]; then
        RUN_STR="${RUN_STR} --novram"
    fi
    if [ "${COMFYUI_CPU_ONLY}" != "-" ]; then
        RUN_STR="${RUN_STR} --cpu"
    fi
    if [ "${COMFYUI_RESERVE_VRAM}" != "-" ]; then
        RUN_STR="${RUN_STR} --reserve-vram ${COMFYUI_RESERVE_VRAM}"
    fi
    if [ "${COMFYUI_ASYNC_OFFLOAD}" != "-" ]; then
        RUN_STR="${RUN_STR} --async-offload"
    fi
    if [ "${COMFYUI_FORCE_NON_BLOCKING}" != "-" ]; then
        RUN_STR="${RUN_STR} --force-non-blocking"
    fi
    if [ "${COMFYUI_DEFAULT_HASHING_FUNCTION}" != "-" ]; then
        RUN_STR="${RUN_STR} --default-hashing-function ${COMFYUI_DEFAULT_HASHING_FUNCTION}"
    fi
    if [ "${COMFYUI_DISABLE_SMART_MEMORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-smart-memory"
    fi
    if [ "${COMFYUI_DETERMINISTIC}" != "-" ]; then
        RUN_STR="${RUN_STR} --deterministic"
    fi
    if [ "${COMFYUI_FAST}" != "-" ]; then
        RUN_STR="${RUN_STR} --fast ${COMFYUI_FAST}"
    fi
    if [ "${COMFYUI_MMAP_TORCH_FILES}" != "-" ]; then
        RUN_STR="${RUN_STR} --mmap-torch-files"
    fi
    if [ "${COMFYUI_DISABLE_MMAP}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-mmap"
    fi
    if [ "${COMFYUI_DONT_PRINT_SERVER}" != "-" ]; then
        RUN_STR="${RUN_STR} --dont-print-server"
    fi
    if [ "${COMFYUI_QUICK_TEST_FOR_CI}" != "-" ]; then
        RUN_STR="${RUN_STR} --quick-test-for-ci"
    fi
    if [ "${COMFYUI_DISABLE_METADATA}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-metadata"
    fi
    if [ "${COMFYUI_DISABLE_ALL_CUSTOM_NODES}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-all-custom-nodes"
    fi
    if [ "${COMFYUI_WHITELIST_CUSTOM_NODES}" != "-" ]; then
        RUN_STR="${RUN_STR} --whitelist-custom-nodes \"${COMFYUI_WHITELIST_CUSTOM_NODES}\""
    fi
    if [ "${COMFYUI_DISABLE_API_NODES}" != "-" ]; then
        RUN_STR="${RUN_STR} --disable-api-nodes"
    fi
    if [ "${COMFYUI_MULTI_USER}" != "-" ]; then
        RUN_STR="${RUN_STR} --multi-user"
    fi
    if [ "${COMFYUI_LOG_STDOUT}" != "-" ]; then
        RUN_STR="${RUN_STR} --log-stdout"
    fi
    # not adding though front-end-version, as it will break the system.
    if [ "${COMFYUI_FRONTEND_ROOT}" != "-" ]; then
        RUN_STR="${RUN_STR} --front-end-root \"${COMFYUI_FRONTEND_ROOT}\""
    fi
    if [ "${COMFYUI_USER_DIRECTORY}" != "-" ]; then
        RUN_STR="${RUN_STR} --user-directory \"${COMFYUI_USER_DIRECTORY}\""
    fi
    if [ "${COMFYUI_ENABLE_COMPRESS_RESPONSE_BODY}" != "-" ]; then
        RUN_STR="${RUN_STR} --enable-compress-response-body"
    fi
    if [ "${COMFYUI_COMFY_API_BASE}" != "-" ]; then
        RUN_STR="${RUN_STR} --comfy-api-base \"${COMFYUI_COMFY_API_BASE}\""
    fi
    if [ "${COMFYUI_DATABASE_URL}" != "-" ]; then
        RUN_STR="${RUN_STR} --database-url \"${COMFYUI_DATABASE_URL}\""
    fi
    if [ "${COMFYUI_EXTRA}" != "-" ]; then
        RUN_STR="${RUN_STR} ${COMFYUI_EXTRA}"
    fi
fi

source venv/bin/activate

if [ -z "${RUN_STR}" ]; then
    bash -c "__python ./main.py___default_args___"
else
    bash -c "__python ./main.py ${RUN_STR}"
fi
