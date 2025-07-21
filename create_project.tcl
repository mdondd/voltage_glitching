set part "xc7a35tcpg236-1"
set proj_name "VoltageGlitching"

create_project $proj_name -dir ./project -part $part

# Set sources & top module
add_files -norecurse -fileset sources_1 {
./sv/glitch.sv
./sv/top.sv
./sv/uart.sv
./sv/uart_tx.sv
}

set_property top "top" [current_fileset]

update_compile_order -fileset sources_1

# Add constraints file
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

set obj [get_filesets constrs_1]

set file "[file normalize "./constraints/constraints.xdc"]"
set file_imported [import_files -fileset constrs_1 [list $file]]
set file "constraints.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Synthesize
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xc7a35tcpg236-1 -flow {Vivado Synthesis 2023} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2023" [get_runs synth_1]
}

#launch_runs synth_1 jobs 16
#wait_on_run synth_1
#launch_runs impl_1 jobs 16
#wait_on_run impl_1

exit
