#!/bin/bash
if [ ! -f ~/.config/orcaslicer/configured ]; then
    mkdir -p ~/.config/orcaslicer/
    touch ~/.config/orcaslicer/configured
    /opt/orcaslicer/DockerBuild2.sh
fi
/opt/orcaslicer/DockerRun.sh || echo " [ INFO ] If you have just reinstalled the package, please remove the file ~/.config/orcaslicer/configured and restart program."
