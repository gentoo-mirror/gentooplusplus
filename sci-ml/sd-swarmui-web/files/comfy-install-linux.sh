#!/usr/bin/env bash

# Check if GPU type is provided
if [ $# -eq 0 ]; then
    >&2 echo "Error: GPU type not specified. Please use 'cpu', 'amd', 'nv', 'ipex' or 'intel' as an argument."
    exit 1
fi

GPU_TYPE=$1
python=$2

# Validate GPU type
if [ "$GPU_TYPE" != "cpu" ] && [ "$GPU_TYPE" != "amd" ] && [ "$GPU_TYPE" != "amd2" ]&& [ "$GPU_TYPE" != "amd3" ] && [ "$GPU_TYPE" != "nv" ] && [ "$GPU_TYPE" != "intel" ] && [ "$GPU_TYPE" != "ipex" ]; then
    >&2 echo "Error: Invalid GPU type. Please use 'cpu', 'amd', 'intel', 'ipex' or 'nv'."
    exit 1
fi

mkdir -p dlbackend

cd dlbackend

git clone https://github.com/comfyanonymous/ComfyUI

cd ComfyUI

# Try to find a good python executable, and dodge unsupported python versions
#for pyvers in python3.11 python3.10 python3.12 python3 python
#for pyvers in python3 python
#do
#    python=`which $pyvers`
#    if [ "$python" != "" ]; then
#        break
#    fi
#done
#if [ "$python" == "" ]; then
#    >&2 echo "ERROR: cannot find python3"
#    >&2 echo "Please follow the install instructions in the readme!"
#    exit 1
#fi

# Validate venv
venv=`$python -m venv 2>&1`
case $venv in
    *usage*)
        :
    ;;
    *)
        >&2 echo "ERROR: python venv is not installed"
        >&2 echo "Please follow the install instructions in the readme!"
        >&2 echo "If on Ubuntu/Debian, you may need: sudo apt install python3-venv"
        exit 1
    ;;
esac

if [ "$GPU_TYPE" == "nv" ]; then
    export PATH="${PATH}:/opt/genai/.dotnet:/opt/swarmui/.dotnet:/opt/cuda/bin/"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/cuda/lib64/"
    export CUDA_HOME="/opt/cuda/"
    export PKG_CONFIG_PATH="/opt/cuda/pkgconfig"
else
    export CUDA_VISIBLE_DEVICES=-1
fi

# Make and activate the venv. "python3" in the venv is now the python executable.
if [ -z "${SWARM_NO_VENV}" ]; then
    echo "Making venv..."
    $python -s -m venv venv
    source venv/bin/activate
    python=python3
    python3 -m ensurepip --upgrade
    $python -s -m pip install --upgrade pip
else
    echo "swarm_no_venv set, will not create venv"
fi

# Install PyTorch based on GPU type
if [ "$GPU_TYPE" == "nv" ]; then
    echo "install nvidia torch..."
    $python -s -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
   # $python -s -m pip install torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124 --extra-index-url https://download.pytorch.org/whl/cu124
elif [ "$GPU_TYPE" == "amd" ] || [ "$GPU_TYPE" == "amd2" ] || [ "$GPU_TYPE" == "amd3" ]; then
    echo "install amd torch..."
    $python -s -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.4
elif [ "$GPU_TYPE" == "cpu" ]; then
    echo "install cpu torch..."
    $python -s -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    $python -s -m pip install intel-extension-for-pytorch
    echo "args.cpu = True
" >> comfy/cli_args.py
elif [ "$GPU_TYPE" == "intel" ]; then
    echo "install intel torch..."
    echo "https://docs.pytorch.org/docs/main/notes/get_start_xpu.html"
    echo "Validated Hardware:"
    echo " * Intel® Arc A-Series Graphics (CodeName: Alchemist)"
    echo " * Intel® Arc B-Series Graphics (CodeName: Battlemage)"
    echo " * Intel® Core™ Ultra Processors with Intel® Arc™ Graphics (CodeName: Meteor Lake-H)"
    echo " * Intel® Core™ Ultra Desktop Processors (Series 2) with Intel® Arc™ Graphics (CodeName: Lunar Lake)"
    echo " * Intel® Core™ Ultra Mobile Processors (Series 2) with Intel® Arc™ Graphics (CodeName: Arrow Lake-H)"
    echo " * Intel® Data Center GPU Max Series (CodeName: Ponte Vecchio)"
    #$python -s -m pip install torch==1.10.0a0 intel-extension-for-pytorch==1.10.200+gpu --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
    #$python -s -m pip install torchvision==0.11.0+cpu --no-deps --index-url https://download.pytorch.org/whl/cpu
    $python -s -m pip install torch==2.1.0a0 torchvision==0.16.0a0 torchaudio==2.1.0a0 intel-extension-for-pytorch==2.1.10+xpu --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
elif [ "$GPU_TYPE" == "ipex" ]; then
    echo "install intel IPEX torch..."
    echo "Prebuilt wheel files are available for Python 3.9, 3.10, 3.11, 3.12, 3.13, 3.13t."
    echo "Documentation can be found here: https://pytorch-extension.intel.com/installation?platform=gpu&version=v2.7.10%2Bxpu&os=linux%2Fwsl2&package=pip"
    echo "Supported by prebuilt binaries:"
    echo " * Intel® Arc™ B-Series Graphics (Intel® Arc™ B580 [Verified], Intel® Arc™ B570)"
    echo " * Intel® Arc™ A-Series Graphics (Intel® Arc™ A770 [Verified], Intel® Arc™ A750, Intel® Arc™ A580, Intel® Arc™ A770M, Intel® Arc™ A730M, Intel® Arc™ A550M)"
    echo " * Intel® Data Center GPU Max Series [Verified]"
    echo " For GPUs newer than Intel® Core™ Ultra Processors with Intel® Arc™ Graphics (Meteor Lake) "
    echo " or Intel® Arc™ A-Series Graphics that aren't listed, "
    echo " please check the AOT documentation ( https://www.intel.com/content/www/us/en/docs/dpcpp-cpp-compiler/developer-guide-reference/2025-0/ahead-of-time-compilation.html ) to see if it is supported. If so, follow instructions in the source section above to compile from source."
    $python -s -m pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/xpu
    $python -s -m pip install intel-extension-for-pytorch==2.8.10+xpu oneccl_bind_pt==2.8.0+xpu --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
fi

echo "install general requirements..."

$python -s -m pip install -r requirements.txt
if [ "$GPU_TYPE" == "nv" ]; then
    echo "Installing additional modules"
    $python -s -m pip install rembg onnxruntime matplotlib opencv-python-headless imageio-ffmpeg dill omegaconf ultralytics comfyui_frontend_package
else
    if [ "$GPU_TYPE" != "amd" ] && [ "$GPU_TYPE" != "amd2" ] && [ "$GPU_TYPE" != "amd3" ]; then
        sed -i "s/os.environ\['HIP_VISIBLE_DEVICES'\] = str(devices)/os.environ['HIP_VISIBLE_DEVICES'] = '-1'/" "main.py"
        sed -i "s/os.environ\['HIP_VISIBLE_DEVICES'\] = str(args.cuda_device)/os.environ['HIP_VISIBLE_DEVICES'] = '-1'/" "main.py"
    fi
    if [ "$GPU_TYPE" != "nv" ]; then
        sed -i "/import os/a os.environ\['CUDA_VISIBLE_DEVICES'\] = '-1'" "main.py"
        sed -i "s/os.environ\['CUDA_VISIBLE_DEVICES'\] = str(devices)/os.environ\['CUDA_VISIBLE_DEVICES'\] = '-1'/" "main.py"
        sed -i "s/os.environ\['CUDA_VISIBLE_DEVICES'\] = str(args.cuda_device)/os.environ\['CUDA_VISIBLE_DEVICES'\] = '-1'/" "main.py"
    fi
    if [ "$GPU_TYPE" == "amd2" ]; then
        sed -i "/import os/a os.environ\['HSA_OVERRIDE_GFX_VERSION'\] = '10.3.0'" "main.py"
    fi
    if [ "$GPU_TYPE" == "amd3" ]; then
        sed -i "/import os/a os.environ\['HSA_OVERRIDE_GFX_VERSION'\] = '11.0.0'" "main.py"
    fi
    if [ "$GPU_TYPE" == "ipex" ] || [ "$GPU_TYPE" == "intel" ]; then
        TEST_INTEL_GPU=`python -c "import torch;print(torch.xpu.is_available())" | tail -n 1`
        if [ "$TEST_INTEL_GPU" == "False" ]; then
            echo ""
            echo ""
            echo "!!! Your Intel GPU was NOT detected !!!"
            echo ""
            echo ""
        fi
    fi
fi

# Just for a pretty message
if [ "$GPU_TYPE" == "amd" ]; then
    GPU_TYPE="AMD (ROCm) GPU"
fi
if [ "$GPU_TYPE" == "amd2" ]; then
    GPU_TYPE="AMD (RDNA2 or older) GPU"
fi
if [ "$GPU_TYPE" == "amd3" ]; then
    GPU_TYPE="AMD (RDNA3) GPU"
fi
if [ "$GPU_TYPE" == "intel" ]; then
    GPU_TYPE="Intel (XPU) GPU"
fi
if [ "$GPU_TYPE" == "ipex" ]; then
    GPU_TYPE="Intel (IPEX) GPU"
fi
if [ "$GPU_TYPE" == "nv" ]; then
    GPU_TYPE="NVidia GPU"
fi
if [ "$GPU_TYPE" == "cpu" ]; then
    GPU_TYPE="CPU only"
fi
echo "Installation completed for $GPU_TYPE."
