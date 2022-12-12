all: compile run-gui

compile:
	vlog -work work +acc=blnr -noincr -timescale 1ns/1ps -f ahblite_sys.vc
	vopt -work work ahblite_sys_tb -o work_opt 

run-gui:
	vsim work_opt -gui 

# clean:
# 	rm -rf work
# 	rm -rf work
# 	rm -rf vsim.wlf
# 	rm -rf transcript

