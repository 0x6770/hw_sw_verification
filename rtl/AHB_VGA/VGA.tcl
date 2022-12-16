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
