proc get_ports {port} {
    global expected
    if {![dict exists $expected $port]} {
        error "Unexpected port: $port"
    }
    return $port
}

proc set_property {option properties port} {
    global expected assigned used_pins
    if {$option ne "-dict" || [llength $properties] != 4} {
        error "Unexpected set_property form"
    }
    set pin [dict get $properties PACKAGE_PIN]
    if {$pin ne [dict get $expected $port]} {
        error "Wrong pin for $port: $pin"
    }
    if {[dict get $properties IOSTANDARD] ne "LVCMOS33"} {
        error "Wrong IOSTANDARD for $port"
    }
    if {[dict exists $assigned $port] || $pin in $used_pins} {
        error "Duplicate port or pin: $port / $pin"
    }
    dict set assigned $port $pin
    lappend used_pins $pin
}

proc create_clock {name_flag name period_flag period port} {
    global clocks
    if {$name_flag ne "-name" || $name ne "sys_clk" ||
        $period_flag ne "-period" || $period != 10.0 || $port ne "clk"} {
        error "Expected a 100 MHz clock on clk"
    }
    incr clocks
}

set root [file dirname [file normalize [info script]]]
foreach design {dff reg8file} {
    set expected [dict create clk P17 clr R17 en P5]
    if {$design eq "dff"} {
        dict set expected d R1
        dict set expected q K2
    } else {
        foreach {bus pins} {
            wsel {R1 N4 M4}
            rsel {R2 P2 P3}
            d {T5 T3 R3 V4 V5 V2 U2 U3}
            q {K2 J2 J3 H4 J4 G3 G4 F6}
        } {
            set index 0
            foreach pin $pins {
                dict set expected [format {%s[%d]} $bus $index] $pin
                incr index
            }
        }
    }
    set assigned [dict create]
    set used_pins {}
    set clocks 0
    source [file join $root $design pin.xdc]
    if {[dict size $assigned] != [dict size $expected] || $clocks != 1} {
        error "Missing ports or clock in $design"
    }
    puts "PASS: $design XDC, [dict size $assigned] ports, unique pins, LVCMOS33, 10 ns clock."
}
