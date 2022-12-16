#----------------------------------------
# JasperGold Version Info
# tool      : JasperGold 2018.06
# platform  : Linux 3.10.0-957.21.3.el7.x86_64
# version   : 2018.06p002 64 bits
# build date: 2018.08.27 18:04:53 PDT
#----------------------------------------
# started Thu Dec 15 21:34:49 GMT 2022
# hostname  : ee-mill3.ee.ic.ac.uk
# pid       : 77726
# arguments : '-label' 'session_0' '-console' 'ee-mill3.ee.ic.ac.uk:39910' '-style' 'windows' '-data' 'AQAAADx/////AAAAAAAAA3oBAAAAEABMAE0AUgBFAE0ATwBWAEU=' '-proj' '/home/jl1719/nfshome/AHB_peripherals_files/rtl/AHB_VGA/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/jl1719/nfshome/AHB_peripherals_files/rtl/AHB_VGA/jgproject/.tmp/.initCmds.tcl' 'VGA.tcl'
# Script for multiplier example in JasperGold
clear -all
analyze -clear
analyze -sv DLS_TOP.sv COMP.sv AHBVGASYS.sv AHBVGASYS_r.sv vga_sync.sv vga_console.sv vga_image.sv counter.sv dual_port_ram_sync.sv font_rom.sv
elaborate -bbox_mul 64 -top DLS_TOP


# Setup global clocks and resets
clock vga_if.HCLK
reset -expression !(vga_if.HRESETn)

# Setup task
task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4

# cover -name test_cover_from_tcl {@(posedge clk) disable iff (!rst_n) done && ab == 10'd35}
prove -bg -all
