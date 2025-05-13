# operating conditions and boundary conditions #
set CLOCK "clk"
set CLOCK_PERIOD  2.0;

create_clock -name $CLOCK -period $CLOCK_PERIOD [get_ports $CLOCK]
set_ideal_network                               [get_ports $CLOCK]
set_dont_touch_network                          [get_clocks $CLOCK]
set_fix_hold                                    [get_clocks $CLOCK]
set_clock_uncertainty  0.1                      [get_clocks $CLOCK]
set_clock_latency      0.5                      [get_clocks $CLOCK]

set_input_delay  0.50 -clock $CLOCK [remove_from_collection [all_inputs] [get_ports $CLOCK]]
set_output_delay 0.50 -clock $CLOCK [all_outputs]
set_drive        1.0                [all_inputs]
set_load         0.05               [all_outputs]

set_min_library N16ADFP_StdCellss0p72v125c_ccs.db -none
set_operating_conditions  -max ss0p72v125c
set_wire_load_model -name ZeroWireload -library N16ADFP_StdCellss0p72v125c_ccs                        

set_max_fanout 20 [all_inputs]
