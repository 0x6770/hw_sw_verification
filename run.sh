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
     -timescale 1ns/1ps \
     -f ahblite_sys.vc \

vopt -work work ahblite_sys_tb -o work_opt
vsim  work_opt -do run_test.tcl