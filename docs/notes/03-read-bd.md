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

## Try 2: Steal Board File from `cpu_ahb2`

For my second try, I am going to steal some files from an existing vivado
project: 

``` 
cpu_ahb2.gen/
cpu_ahb2.srcs/
```

and import the board file unmodified:

``` tcl
set boardFile "./vivado/cpu_ahb2/cpu_ahb2.srcs/sources_1/bd/cpu/cpu.bd"
read_bd $boardFile
```

Which gives me a cryptic warning:

``` bash
# set boardFile "./vivado/cpu_ahb2/cpu_ahb2.srcs/sources_1/bd/cpu/cpu.bd"
# read_bd ./vivado/cpu_ahb2/cpu_ahb2.srcs/sources_1/bd/cpu/cpu.bd
INFO: [BD 5-945] read_bd has been aliased to the add_files Tcl command to ensu
re all associated files with the BD are included with the design.  All message
s will reference the add_files Tcl command
INFO: [IP_Flow 19-234] Refreshing IP repositories
INFO: [IP_Flow 19-1704] No user IP repositories specified
INFO: [IP_Flow 19-2313] Loaded Vivado IP repository 'C:/Xilinx/Vivado/2024.2/d
ata/ip'.
WARNING: [BD 41-1661] One or more IPs have been locked in the design 'cpu.bd'.
 Please run report_ip_status for more details and recommendations on how to fi
x this issue.
List of locked IPs:
cpu_proc_sys_reset_0_0
cpu_processing_system7_0_0
cpu_smartconnect_0_0
```

Adding the recommended command (`report_ip_status -file ...`) gives me an output
report:

``` tcl
Copyright 1986-2022 Xilinx, Inc. All Rights Reserved. Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
---------------------------------------------------------------------------------------------------------------------------------------------
| Tool Version : Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
| Date         : Tue Jun 24 15:12:28 2025
| Host         : ISCN5CG2423R5R running 64-bit major release  (build 9200)
| Command      : report_ip_status
---------------------------------------------------------------------------------------------------------------------------------------------

IP Status Summary

1. Project IP Status
--------------------
Your project uses 17 IP. Some of these IP may have undergone changes in this release of the software. Please review the recommended actions.

More information on the Xilinx versioning policy is available at www.xilinx.com.

Project IP Instances
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| Instance Name              | Status                     | Recommendation      | Change    | IP Name            | IP      | New Version   | New        | Original Part        |
|                            |                            |                     | Log       |                    | Version |               | License    |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| cpu_axi_ahblite_bridge_0_0 | Up-to-date                 | No changes required |  *(1)     | AXI AHBLite Bridge | 3.0     | 3.0 (Rev. 30) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 30)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| cpu_proc_sys_reset_0_0     | IP board change            | Retarget IP         |  *(2)     | Processor System   | 5.0     | 5.0 (Rev. 16) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | Reset              | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 16)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| cpu_processing_system7_0_0 | IP board change            | Retarget IP         |  *(3)     | ZYNQ7 Processing   | 5.5     | 5.5 (Rev. 6)  | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | System             | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 6)      |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| cpu_smartconnect_0_0       | IP contains locked subcore | Upgrade IP          |  *(4)     | AXI SmartConnect   | 1.0     | 1.0 (Rev. 25) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 25)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_m00e_0             | Up-to-date                 | No changes required |  *(5)     | SC EXIT            | 1.0     | 1.0 (Rev. 16) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 16)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_m00s2a_0           | Up-to-date                 | No changes required |  *(6)     | SmartConnect       | 1.0     | 1.0 (Rev. 10) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | SC2AXI Bridge      | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 10)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_one_0              | Up-to-date                 | No changes required |  *(7)     | Constant           | 1.1     | 1.1 (Rev. 9)  | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 9)      |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_psr_aclk_0         | IP board change            | Repackage parent IP |  *(8)     | Processor System   | 5.0     | 5.0 (Rev. 16) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | Reset              | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 16)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_s00a2s_0           | Up-to-date                 | No changes required |  *(9)     | SmartConnect       | 1.0     | 1.0 (Rev. 10) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | AXI2SC Bridge      | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 10)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_s00mmu_0           | Up-to-date                 | No changes required |  *(10)    | SC MMU             | 1.0     | 1.0 (Rev. 14) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 14)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_s00sic_0           | Up-to-date                 | No changes required |  *(11)    | SC SI_CONVERTER    | 1.0     | 1.0 (Rev. 14) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 14)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_s00tr_0            | Up-to-date                 | No changes required |  *(12)    | SC                 | 1.0     | 1.0 (Rev. 11) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           | TRANSACTION_REGULA | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 11)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_sarn_0             | Up-to-date                 | No changes required |  *(13)    | SmartConnect Node  | 1.0     | 1.0 (Rev. 17) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 17)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_sawn_0             | Up-to-date                 | No changes required |  *(14)    | SmartConnect Node  | 1.0     | 1.0 (Rev. 17) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 17)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_sbn_0              | Up-to-date                 | No changes required |  *(15)    | SmartConnect Node  | 1.0     | 1.0 (Rev. 17) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 17)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_srn_0              | Up-to-date                 | No changes required |  *(16)    | SmartConnect Node  | 1.0     | 1.0 (Rev. 17) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 17)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
| bd_9332_swn_0              | Up-to-date                 | No changes required |  *(17)    | SmartConnect Node  | 1.0     | 1.0 (Rev. 17) | Included   | xc7z020clg400-1      |
|                            |                            |                     |           |                    | (Rev.   |               |            |                      |
|                            |                            |                     |           |                    | 17)     |               |            |                      |
+----------------------------+----------------------------+---------------------+-----------+--------------------+---------+---------------+------------+----------------------+
*(1) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/axi_ahblite_bridge_v3_0/doc/axi_ahblite_bridge_v3_0_changelog.txt
*(2) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/proc_sys_reset_v5_0/doc/proc_sys_reset_v5_0_changelog.txt
*(3) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/processing_system7_v5_5/doc/processing_system7_v5_5_changelog.txt
*(4) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/smartconnect_v1_0/doc/smartconnect_v1_0_changelog.txt
*(5) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_exit_v1_0/doc/sc_exit_v1_0_changelog.txt
*(6) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_sc2axi_v1_0/doc/sc_sc2axi_v1_0_changelog.txt
*(7) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/xlconstant_v1_1/doc/xlconstant_v1_1_changelog.txt
*(8) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/proc_sys_reset_v5_0/doc/proc_sys_reset_v5_0_changelog.txt
*(9) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_axi2sc_v1_0/doc/sc_axi2sc_v1_0_changelog.txt
*(10) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_mmu_v1_0/doc/sc_mmu_v1_0_changelog.txt
*(11) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_si_converter_v1_0/doc/sc_si_converter_v1_0_changelog.txt
*(12) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_transaction_regulator_v1_0/doc/sc_transaction_regulator_v1_0_changelog.txt
*(13) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_node_v1_0/doc/sc_node_v1_0_changelog.txt
*(14) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_node_v1_0/doc/sc_node_v1_0_changelog.txt
*(15) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_node_v1_0/doc/sc_node_v1_0_changelog.txt
*(16) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_node_v1_0/doc/sc_node_v1_0_changelog.txt
*(17) c:/Xilinx/Vivado/2024.2/data/ip/xilinx/sc_node_v1_0/doc/sc_node_v1_0_changelog.txt
```

This indicates to me that .... this won't work. :( I can't update the IP
properly, so we're back to square one.
