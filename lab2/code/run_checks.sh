#!/bin/sh
set -eu

code_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_dir="$code_dir/build"
mkdir -p "$build_dir"
cd "$code_dir"

iverilog -g2012 -Wall -s dff_check -o "$build_dir/dff_check.vvp" dff/dff.v dff/dff_check.v
vvp "$build_dir/dff_check.vvp"
iverilog -g2012 -Wall -s reg8file_check -o "$build_dir/reg8file_check.vvp" reg8file/reg8file.v reg8file/reg8file_check.v
vvp "$build_dir/reg8file_check.vvp"
iverilog -g2012 -Wall -s dff_sim -o "$build_dir/dff_sim.vvp" dff/dff.v dff/dff_sim.v
iverilog -g2012 -Wall -s testbench -o "$build_dir/reg8file_sim.vvp" reg8file/reg8file.v reg8file/testbench.v
tclsh check_xdc.tcl

cd "$build_dir"
vvp dff_sim.vvp +vcd
vvp reg8file_sim.vvp +vcd
python3 "$code_dir/check_waveforms.py"
