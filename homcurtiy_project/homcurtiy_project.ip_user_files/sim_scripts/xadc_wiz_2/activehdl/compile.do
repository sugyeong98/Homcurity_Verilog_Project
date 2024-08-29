vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 \
"../../../../homcurtiy_project.srcs/sources_1/ip/xadc_wiz_2/xadc_wiz_2.v" \


vlog -work xil_defaultlib \
"glbl.v"

