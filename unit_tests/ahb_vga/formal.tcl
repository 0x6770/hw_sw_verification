# Script for multiplier example in JasperGold
clear -all
analyze -clear
analyze -sv -f file_list
elaborate -bbox_mul 64 -top DLS_TOP


# Setup global clocks and resets
clock vga_if.HCLK
reset -expression !(vga_if.HRESETn)

# Setup task
task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4

prove -all