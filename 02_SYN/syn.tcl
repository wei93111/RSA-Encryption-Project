set hdlin_translate_off_skip_text "TRUE"
set edifout_netlist_only "TRUE"
set verilogout_no_tri true
set hdlin_enable_presto_for_vhdl "TRUE"
set sh_enable_line_editing true
set sh_line_editing_mode emacs

sh mkdir -p Netlist
sh mkdir -p Report

set DESIGN "RSA"

# Import Design
read_verilog {../01_RTL/RSA.v, ../01_RTL/RsaCore.v, ../01_RTL/Fifo.v}
elaborate $DESIGN
current_design $DESIGN
uniquify
link

source -echo -verbose ./RSA.sdc
set high_fanout_net_threshold 0
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
check_design
# Compile Design
compile

# Dump Report
report_area > "./Report/${DESIGN}_syn.area"
report_timing -max_path 20 -delay_type max > "Report/${DESIGN}_syn.max.timing"
report_timing -max_path 20 -delay_type min > "Report/${DESIGN}_syn.min.timing"
report_timing > "./Report/${DESIGN}_syn.timing"

# Output Design
set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]
set verilogout_higher_designs_first true
write -format ddc     -hierarchy -output "./Netlist/${DESIGN}_syn.ddc"
write -format verilog -hierarchy -output "./Netlist/${DESIGN}_syn.v"
write_sdf -version 2.1 ./Netlist/${DESIGN}_syn.sdf
write_sdc ./Netlist/${DESIGN}_syn.sdc

check_design
report_timing
report_area
exit
