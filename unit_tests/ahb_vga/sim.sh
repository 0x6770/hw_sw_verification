#!/bin/bash

set -e

# source config for QUESTA
source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh

# remove previous files if exist
rm -rf work
rm -rf work_opt

vlib work
vlog -work work \
     +acc=blnr \
     -noincr \
     +cover \
     -timescale 1ns/1ps \
     -f file_list \
     # +define+DEBUG
vopt -work work vga_top -o work_opt
vsim -c -coverage work_opt -do run_test.tcl

vcover report -details -html testdb.ucdb