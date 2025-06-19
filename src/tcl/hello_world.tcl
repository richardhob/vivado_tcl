# Define / Create an Output Directory

set partNum "xc7z020clg400-1"
set outputDir ./build

file mkdir $outputDir

# Delete all the files in the output directory if there are any
set files [glob -nocomplain "$outputDir/*"]

if {[llength $files] != 0} {
    puts "Cleaning $outputDir"
    file delete -force {*}[glob -directory $outputDir *]
} else {
    puts "$outputDir is Empty"
}

read_verilog [ glob ./src/v/*.v ]
read_xdc ./src/Zybo-Z7-Master.xdc

# Synthesize
synth_design -top Blinky -part $partNum
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_syth_utilization.rpt

# Optimize
opt_design
place_design
report_clock_utilization -file $outputDir/clock_util.rpt

if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
    puts "Timing Violations: Running Physical Optimization"
    phys_opt_design
}

write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_utilization.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt

# Route
route_design -directive Explore
write_checkpoint -force $outputDir/post_route.dcp

report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/report_timing_summary.rpt 
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_route_drc.rpt

# Bitfile
write_verilog -force $outputDir/cpu_impl_netlist.v -mode timesim -sdf_anno true
write_bitstream -force $outputDir/blinky.bit
