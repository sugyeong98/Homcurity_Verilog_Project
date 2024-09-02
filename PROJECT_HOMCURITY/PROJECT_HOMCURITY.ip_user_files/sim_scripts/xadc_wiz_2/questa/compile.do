vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../PROJECT_HOMCURITY.srcs/sources_1/ip/xadc_wiz_2/xadc_wiz_2.v" \


vlog -work xil_defaultlib \
"glbl.v"

