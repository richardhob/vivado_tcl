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

read_bd ./src/bd/computer.bd
read_xdc ./src/Zybo-Z7-Master.xdc
generate_target all [get_ips]
