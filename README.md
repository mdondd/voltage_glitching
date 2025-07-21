# Voltage Fault Injection Tool
A simple FPGA-based voltage fault injection tool. Currently, the code targets the Digilent Cmod A7, a cheap Xilinx FPGA.

## Building
First, create the Vivado project:
```
./create_project.sh
```
Then, you can open the create project file and build it via the GUI.

We provide a FPGA flash script for convenience to flash the connected FPGA via the command line:
```
./flash.sh
```

## Usage
The host control part is implemented in `host/glitch.py`. This file contains all code to configure the glitch offset, width, trigger, arming etc.