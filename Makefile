all: compile run-gui

compile:
	vlog -work work +acc=blnr -noincr -timescale 1ns/1ps -f ahblite_sys.vc
	vopt -work work ahblite_sys_tb -o work_opt 

run-gui:
	vsim -c work_opt -do run_test.tcl


# clean:
# 	rm -rf work
# 	rm -rf work
# 	rm -rf vsim.wlf
# 	rm -rf transcript
#   vsim work_opt -gui 

