# Modified version for OpenOCD compatibility
proc mrd {addr} {
    # Convert address to numeric if it's a string
    if {[string is integer -strict $addr] == 0} {
        set addr [expr $addr]
    }
    
    # Read memory and extract just the value portion
    set result [mdw $addr]
    # Parse out just the value from something like "0xf8007080: 30800100"
    set value [lindex [split $result ":"] 1]
    # Clean up any spaces and format consistently
    set value [string trim $value]
    return $value
}

# Define mwr (memory write) command for OpenOCD
proc mwr {args} {
    # Parse arguments
    set force 0
    set addr 0
    set value 0
    
    if {[lindex $args 0] == "-force"} {
        set force 1
        set addr [lindex $args 1]
        set value [lindex $args 2]
    } else {
        set addr [lindex $args 0]
        set value [lindex $args 1]
    }
    
    # Convert address and value to numeric if they're strings
    if {[string is integer -strict $addr] == 0} {
        set addr [expr $addr]
    }
    if {[string is integer -strict $value] == 0} {
        set value [expr $value]
    }
    
    # Write to memory
    mww $addr $value
    return
}

proc mask_write {addr mask data} {
    # Read current value
    set result [mdw $addr]
    set value [lindex [split $result ":"] 1]
    set value [string trim $value]
    set value 0x$value
    
    # Apply mask and data
    set new_value [expr {($value & ~($mask)) | ($data & $mask)}]
    
    # Write back
    mww $addr $new_value
}

# Dummy configparams implementation for OpenOCD compatibility
proc configparams {args} {
    # If one argument (query mode), just return a dummy value
    if {[llength $args] == 1} {
        return 0
    }
    
    # If two arguments (set mode), do nothing and return success
    return 1
}
