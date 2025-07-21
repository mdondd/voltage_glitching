open_hw_manager

connect_hw_server -url localhost:3121
current_hw_server

open_hw_target

# just use the first device
current_hw_device [lindex [get_hw_devices] 0]

set_property PROGRAM.FILE {project/VoltageGlitching.runs/impl_1/fault_injection_top.bit} [current_hw_device]
program_hw_devices [current_hw_device]

close_hw_manager

exit