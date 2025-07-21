#!/bin/bash

rm -rf project

source /opt/xilinx/Vivado/2024.2/settings64.sh
vivado -mode tcl -source create_project.tcl -nojournal -nolog