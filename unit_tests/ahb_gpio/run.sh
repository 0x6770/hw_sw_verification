#!/bin/bash

set -e

source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh

vlib work
vlog -work work +acc=blnr -noincr -timescale 1ns/1ps -f file_list.sv
vopt -work work top -o work_opt
vsim -c work_opt -do run_test.tcl
