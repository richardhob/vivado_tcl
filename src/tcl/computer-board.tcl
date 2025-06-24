# Create Zynq Processor System stuffs
set outputDir ./build
set bdDir "$outputDir/bd"
set partNum "xc7z020clg400-1"

# Create directories
file mkdir $outputDir
file mkdir $bdDir

# Clean out old IP
set bdFiles [glob -nocomplain "$bdDir/*"]

if {[llength $bdFiles] != 0} {
    puts "Cleaning $bdDir"
    file delete -force {*}[glob -directory $bdDir *]
} else {
    puts "$bdDir is Empty"
}

create_project -in_memory -part $partNum

set boardFile "./vivado/cpu_ahb2/cpu_ahb2.srcs/sources_1/bd/cpu/cpu.bd"

read_bd $boardFile
read_xdc ./src/Zybo-Z7-Master.xdc
report_ip_status -file $outputDir/ip_status.txt
generate_target all [get_files $boardFile]
