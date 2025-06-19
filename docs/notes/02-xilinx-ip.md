# Xilinx IP

Previously, we got a simple TCL script running, which:

1. Saves checkpoints
2. Builds a Bitfile
3. Generates a number of useful reports

This is a great first step. Unfortunately, we now have to deal with Xilinx IP to
do anything useful. We'll start with the "Gritty Engineer" article, "Creating
Vivado IP the Smart Tcl Way", and go from there.

## Creating IP using TCL Commands

I think it'll make the most sense to create IP using Tcl commands. This allows
me maximum flexibility, so we'll do that. 

The easiest way to figure out how to do this is to open the Vivado GUI, add the 
IP to the project, and check the journal file to see the commands run.

Getting the Journal file:

    File > Project > Open Journal File

An, according to the Gritty Engineer, we are interested in a few things:

- `create_ip`
- `set_property`
- `generate_target`

### `create_ip`

This can be found on Page 357 of the "UG835: Vivado Design Suite Tcl Command
Reference Guide". The only required argument is `-module_name`, which determines
the name of the IP.

One of the things mentioned in the Gritty Engineer article is that we need a
project open to use this... which we can work around using:

``` tcl
create_project -in_memory -part $partNum
```

### Add Zynq 7000 Processing System

``` tcl
create_ip -name processing_system7 -vendor xilinx.com -library ip -version 5.5 -module_name processing_system7_0 -dir build/IP
set_property -dict [list \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {48} \
  CONFIG.PCW_IRQ_F2P_INTR {1} \
  CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
] [get_ips processing_system7_0]
generate_target all [get_files /home/rick/git/fpga/vivado/cpu9/cpu9.srcs/sources_1/ip/processing_system7_0/processing_system7_0.xci]
```

The default `module_name` is `processing_system7` which is neat. The IP Catalog
in Xilinx also has the VNLV, which can simplify the call a tiny bit:

``` tcl
create_ip -vlnv xilinx.com:ip:processing_system7:5.5 -module_name zynq_cpu -dir $ipDir
```

We can generate some targets using `generate_target`:

``` tcl
generate_target all [get_ips <ip name>]
... OR ...
generate_target all [get_ips]
```

### What is generated in `all`

Let's look at what is generated in the `all` output:

``` bash
> ls build/IP/zynq_cpu/
doc                   ps7_init.h          zynq_cpu.bmj
fixedio_rtl.xml       ps7_init.html       zynq_cpu_bmstub.v
fixedio.xml           ps7_init.tcl        zynq_cpu.veo
hdl                   ps7_parameters.xml  zynq_cpu.vho
hpstatusctrl_rtl.xml  sim                 zynq_cpu.xci
hpstatusctrl.xml      sim_tlm             zynq_cpu.xdc
ps7_init.c            synth               zynq_cpu.xml
ps7_init_gpl.c        usbctrl_rtl.xml
ps7_init_gpl.h        usbctrl.xml
```

The `zynq_cpu_bmstub.v` includes the names of all the verilog lines we need to
work with, so that's awesome. The `hdl` directory has stuff... I'm not sure
what? Maybe it's for simulation.

``` verilog
module zynq_cpu (
  // AXI Master Interface
  M_AXI_GP0_ARVALID,
  M_AXI_GP0_AWVALID,
  M_AXI_GP0_BREADY,
  M_AXI_GP0_RREADY,
  M_AXI_GP0_WLAST,
  M_AXI_GP0_WVALID,
  M_AXI_GP0_ARID,
  M_AXI_GP0_AWID,
  M_AXI_GP0_WID,
  M_AXI_GP0_ARBURST,
  M_AXI_GP0_ARLOCK,
  M_AXI_GP0_ARSIZE,
  M_AXI_GP0_AWBURST,
  M_AXI_GP0_AWLOCK,
  M_AXI_GP0_AWSIZE,
  M_AXI_GP0_ARPROT,
  M_AXI_GP0_AWPROT,
  M_AXI_GP0_ARADDR,
  M_AXI_GP0_AWADDR,
  M_AXI_GP0_WDATA,
  M_AXI_GP0_ARCACHE,
  M_AXI_GP0_ARLEN,
  M_AXI_GP0_ARQOS,
  M_AXI_GP0_AWCACHE,
  M_AXI_GP0_AWLEN,
  M_AXI_GP0_AWQOS,
  M_AXI_GP0_WSTRB,
  M_AXI_GP0_ACLK,
  M_AXI_GP0_ARREADY,
  M_AXI_GP0_AWREADY,
  M_AXI_GP0_BVALID,
  M_AXI_GP0_RLAST,
  M_AXI_GP0_RVALID,
  M_AXI_GP0_WREADY,
  M_AXI_GP0_BID,
  M_AXI_GP0_RID,
  M_AXI_GP0_BRESP,
  M_AXI_GP0_RRESP,
  M_AXI_GP0_RDATA,

  // Interrupts
  IRQ_F2P,

  // Fabric Clock
  FCLK_CLK0,
  FCLK_RESET0_N,

  // ?? Is this the Fixed IO
  MIO,

  // DDR
  DDR_CAS_n,
  DDR_CKE,
  DDR_Clk_n,
  DDR_Clk,
  DDR_CS_n,
  DDR_DRSTB,
  DDR_ODT,
  DDR_RAS_n,
  DDR_WEB,
  DDR_BankAddr,
  DDR_Addr,
  DDR_VRN,
  DDR_VRP,
  DDR_DM,
  DDR_DQ,
  DDR_DQS_n,
  DDR_DQS,

  // Clock and Reset
  PS_SRSTB,
  PS_CLK,
  PS_PORB
);
```

### Other IP

Specifically what other IP do we need. Defaults are fine I think?

- Processor Reset System (`xilinx.com:ip:proc_sys_reset:5.0`)
- AXI AHB Bridge (`xilinx.com:ip:axi_ahblite_bridge:3.0`)

Neither of the AXI connection blocks can be used without the IP Integrator ...

- AXI Smart Connect (`xilinx.com:ip:smartconnect:1.0`)
- AXI Interconnect (`xilinx.com:ip:axi_interconnect:2.1`)

So what do we do about that? Wellllll I think we can get away with routing the
AXI from the CPU directly to the AXI AHB bridge... 

So we're stuck. We can't make a 100% AXI thing without the IP Integrator.

We can (first) try `read_bd`? Maybe we can blob the CPU and the rest of the BS
into a blob that we can ignore.

### So That's it?

Where we're at right now is that we can create IP... but connecting them will be
a tremendous pain. For our CPU, we're going to need:

- Processing System
- AXI interconnect
- Smart AXI Connection Dude
- AXI to AHB Bridge
- Processor Reset System

So... we need a way to connect all this stuff up. interesting. Something for a
future thing.
