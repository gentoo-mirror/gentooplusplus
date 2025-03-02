#!/bin/bash
if [ ! -f ~/.config/orcaslicer/configured ]; then
    mkdir -p ~/.config/orcaslicer/
    touch ~/.config/orcaslicer/configured
    /opt/orcaslicer/DockerBuild2.sh
fi
/opt/orcaslicer/DockerRun.sh
