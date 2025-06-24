# TCL and Vivado

Using TCL to build Vivado project for the Zybo Z7

## Status

The Smart Connect IP is a problem. This IP cannot be added to the project
without the IP Integrator (the schematic capture bits in Vivado), and is
required to connect the Zynq processor to other AXI parts.

Things I have tried:

- [X] Adding "Smart Connect" in TCL (Doesn't work)
- [X] Adding "AXI Interconnect" in TCL (Doesn't work)
- [X] Import Board File from working project (Doesn't work)

The board file didn't work because Vivado wanted to upgrade the IP or something
... including the "Smart Connect"

What could work (requires work):

- [ ] Use Zip CPU AXI Crossbar (Estimate 2m)
- [ ] Find internal AXI Crossbar with support 

Basically we're stuck... so we have to use a manual process for now.
