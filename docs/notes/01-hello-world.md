# TCL, Vivado, and Building Bitfiles

Let's take a quick break from our normal programs to work on an interesting
problem: how can we build our bitfile without the Vivado GUI? Vivado
(fortunately) offers a TCL interface, which should allow us to greatly improve
our FPGA Solution.

Note that I'm using Vivado 2024.2 for this. I am unsure if other versions of
this tool will work for this effort, given the _confusing_ Vivado release
strategy. Maybe it will?

## Hello World

Let's say we want to turn on an LED:

``` verilog
module blinky(
    output LED0,
    input clk
    );
 
reg blink;
initial blink = 0;

reg counter = 8'b0;

assign LED0 = blink;

always @(posedge clk)
begin
    counter = counter + 1;
end

always @(posedge clk)
begin
    if (counter == 0) blink = ~blink;
end

endmodule
```

Simple right?

### First Try: Vivado

Settings this up in vivado was fairly quick. Got the LED0 ON, which is
something. Definititely not using a high enough value for a counter.

One interesting things that I learned here: If there's no CPU connection (IE we
use the external clock), we don't need the `ps7_init.tcl` script. That's cool!
I'll need to modify the OpenOCD programming procedure a bit to conditionally
remove that.

Got the repository set up, so everything works as expected.

### Second Try: TCL

To run TCL files using Vivado:

``` bash
> vivado -mode batch -source ./src/tcl/hello_world.tcl
```

Simple! From the "Gritty Engineer" article on Non-Project mode, first we make
and clean an output directory:

``` tcl
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
```

then we add our source files:

``` tcl
read_vivado [ glob ./src/v/* ]
read_xdc ./src/Zybo-Z7-Master.xdc
```

What's cool is that we can use `-sv` to specify that the Verilog source files
are actually System Verilog, which was a bit of a mess through the Vivado GUI.

To synthesize our project:

``` tcl
synth_design -top Blinky -part $partNum
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_syth_utilization.rpt
```

Writing a checkpoint is convenient - it will allow us to continue our building
process without having to re-synthesize if things fail. The Reports are kinda
cool, and pretty quick to generate.


Next, we can optimize our design:

``` tcl
opt_design
place_design
report_clock_utilization -file $outputDir/clock_util.rpt
```

and if we get timing violations we can run addittional optimizations, which is
only possible in non-project mode:

``` tcl
if {[get_propery SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
    puts "Timing Violations: Running Physical Optimization"
    phys_opt_design
}

write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_utilization.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
```

Now we can route the design. There are apparently different routing directives
that are possible, and `Explore` is one of them.

``` tcl
route_design -directive Explore
write_checkpoint -force $outputDir/post_route.dcp

report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/report_timing_summary.rpt 
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_route_drc.rpt
```

And we can write the bitstream, as well as the netlist in Verilog format:

``` tcl
write_verilog -force $outputDir/cpu_impl_netlist.v -mode timesim -sdf_anno true
write_bitstream -force $outputDir/blinky.bit
```

This works! Programming the bitstream is the next step.... but my kit is being
dumb so I'll do that later. Next, we have to deal with Xilinx IPs.

