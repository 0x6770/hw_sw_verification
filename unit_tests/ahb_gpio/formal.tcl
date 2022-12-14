clear -all
analyze -clear
analyze -sv ../../rtl/AHB_GPIO/AHBGPIO.sv
elaborate -top AHBGPIO

# setup clocks and resets
clock HCLK
reset -expression !(HRESETn)

# setup tasks
set_proofgrid_max_jobs 4
prove -all