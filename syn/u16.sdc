set_time_format -unit ns -decimal_places 3

derive_clock_uncertainty

create_clock -name {clk_12_} -period 83.3333 [get_ports {clk_12_}]

derive_pll_clocks
