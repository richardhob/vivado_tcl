# Create Zynq Processor System stuffs
set outputDir ./build
set ipDir "$outputDir/IP"
set partNum "xc7z020clg400-1"

# Create directories
file mkdir $outputDir
file mkdir $ipDir

# Clean out old IP
set ipFiles [glob -nocomplain "$ipDir/*"]

if {[llength $ipFiles] != 0} {
    puts "Cleaning $ipDir"
    file delete -force {*}[glob -directory $ipDir *]
} else {
    puts "$ipDir is Empty"
}

create_project -in_memory -part $partNum

create_ip -vlnv xilinx.com:ip:processing_system7:5.5 -module_name zynq_cpu -dir $ipDir
set_property -dict [list \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {48} \
  CONFIG.PCW_IRQ_F2P_INTR {1} \
  CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
] [get_ips zynq_cpu]

generate_target all [get_ips zynq_cpu]
