vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr \
"../../../../homcurtiy_project.srcs/sources_1/ip/xadc_wiz_2/xadc_wiz_2.v" \


vlog -work xil_defaultlib \
"glbl.v"

