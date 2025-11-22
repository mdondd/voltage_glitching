#!/bin/bash

rm -rf project

source /opt/vivado/2025.2/Vivado/settings64.sh
vivado -mode tcl -source create_project.tcl -nojournal -nolog