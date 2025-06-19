# Read BD

OK So last time we realized that we can't *just* use any Xilinx IP in the bank.
Which is going to be a problem. There are a number of IP that must be placed in
"IP Integrator" mode. 

So this time, we're going to try and load a board file, and get it to generate
the output products. What I think this will do is read the IP files and how
they're routed from a board file into memory, and allow us to generate things. 

If we're lucky - the board file is a big zip file, which contains the XCI files
and all that.

If we're unlucky - the board file is a big zip file AND there are XCI files hard
coded into it, which map to file in the project we're stealing the board file
from.

Let's steal the board file from "cpu_ahb2." The board file lives at:

    vivado/cpu_ahb2/cpu_ahb2.srcs/sources_1/bd/computer/computer.bd

Opening this we see ... a JSON file which contains mostly just text, which is
good! I see one hard coded address, but we could potentially address that,
specifically the `gen_directory`:

``` json
{
  "design": {
    "design_info": {
      "boundary_crc": "0x50E3DEC4C717A9AA",
      "device": "xc7z020clg400-1",
      "gen_directory": "../../../../cpu_ahb2.gen/sources_1/bd/computer",
      "name": "computer",
      "rev_ctrl_bd_flag": "RevCtrlBdOff",
      "synth_flow_mode": "Hierarchical",
      "tool_version": "2024.2",
      "validated": "true"
    },
```

there is also a CRC which is concerning ... maybe it's for something else? It
looks like a pretty big number. The first thing we will do is copy this into our
project, and change the gen directory to something more reasonable, like
`../../build/bd` since the path looks relative to the board file.

And we'll write a simple Tcl script:

``` Tcl
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
```

So what do we get from this? Informative errors:

``` bash
# read_bd ./src/bd/computer.bd
INFO: [BD 5-945] read_bd has been aliased to the add_files Tcl command to ensure all associated files with the BD are included with the design.  All messages will reference the add_files Tcl command
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_processing_system7_0_0/computer_processing_system7_0_0.xci' referenced by design 'computer' could not be found.
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_proc_sys_reset_0_0/computer_proc_sys_reset_0_0.xci' referenced by design 'computer' could not be found.
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_axi_ahblite_bridge_0_0/computer_axi_ahblite_bridge_0_0.xci' referenced by design 'computer' could not be found.
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_ila_0_0/computer_ila_0_0.xci' referenced by design 'computer' could not be found.
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_axi_interconnect_0_imp_auto_pc_0/computer_axi_interconnect_0_imp_auto_pc_0.xci' referenced by design 'computer' could not be found.
WARNING: [BD 41-2576] File '/home/rick/git/vivado_tcl/src/bd/ip/computer_axi_interconnect_0_0/computer_axi_interconnect_0_0.xci' referenced by design 'computer' could not be found.
ERROR: [BD 41-1942] The design 'computer.bd' is set for Out-of-Context synthesis mode Hierarchical (Out of context per IP) but is not fully generated. Please ensure that design sources are fully generated befor
e adding them to non-project flow. You can also try setting the mode to None (Global Synthesis), or use Save Project As to save your work in a project flow to use this mode.
ERROR: [Common 17-39] 'add_files' failed due to earlier errors.
```

Vivado is saying it can't find the XCI files that are required by the board
file. Which makes perfect sense actually - we haven't made any XCI files. 

We leared that the relative path is the path to the generated files (XCI), and
that we need all the files mentioned here to get it to work correctly.
