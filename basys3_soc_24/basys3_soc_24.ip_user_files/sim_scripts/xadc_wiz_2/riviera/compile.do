vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 \
"../../../../basys3_soc_24.srcs/sources_1/ip/xadc_wiz_2/xadc_wiz_2.v" \


vlog -work xil_defaultlib \
"glbl.v"

