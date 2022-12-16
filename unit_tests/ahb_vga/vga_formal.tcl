# Script for multiplier example in JasperGold
clear -all
analyze -clear
analyze -sv -f file_list
elaborate -bbox_mul 64 -top vga_top


# Setup global clocks and resets
clock clk
#reset -expression !(HRESETn)

# Setup task
task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4

# cover -name test_cover_from_tcl {@(posedge clk) disable iff (!rst_n) done && ab == 10'd35}

#TODO TOMORROW:
#1. Fix formal verification with help of TA
#2. Ensure what i have done now is acceptable: coverage, bug injection
#3. Communicatie with charles to finish-off system-level test
#4. Start on Issbelle