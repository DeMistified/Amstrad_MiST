
# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set sysclk ${topmodule}pll|altpll_component|auto_generated|pll1|clk[0]
set sdramclk ${topmodule}pll|altpll_component|auto_generated|pll1|clk[1]

# Clock groups
set_clock_groups -asynchronous -group [get_clocks spiclk] -group [get_clocks ${topmodule}pll|altpll_component|auto_generated|pll1|clk[*]]

# SDRAM delays
set_input_delay -clock [get_clocks $sdramclk] -reference_pin [get_ports $RAM_CLK] -max 6.4 [get_ports $RAM_IN]
set_input_delay -clock [get_clocks $sdramclk] -reference_pin [get_ports $RAM_CLK] -min 3.2 [get_ports $RAM_IN]

set_output_delay -clock [get_clocks $sdramclk] -reference_pin [get_ports $RAM_CLK] -max 1.5 [get_ports $RAM_OUT]
set_output_delay -clock [get_clocks $sdramclk] -reference_pin [get_ports $RAM_CLK] -min -0.8 [get_ports $RAM_OUT]

# Some relaxed constrain to the VGA pins. The signals should arrive together, the delay is not really important.
set_output_delay -clock [get_clocks $sysclk] -max 0 [get_ports {VGA_*}]
set_output_delay -clock [get_clocks $sysclk] -min -5 [get_ports {VGA_*}]
set_multicycle_path -to [get_ports {VGA_*}] -setup 3
set_multicycle_path -to [get_ports {VGA_*}] -hold 2

set_multicycle_path -from [get_clocks $sdramclk] -to [get_clocks $sysclk] -setup -end 2

# T80 just cannot run in 64 MHz, but it's safe to allow 2 clock cycles for the paths in it
set_multicycle_path -from ${topmodule}motherboard|CPU|u0|* -setup 2
set_multicycle_path -from ${topmodule}motherboard|CPU|u0|* -hold 1



# False paths

# Don't bother optimizing sigma_delta_dac
set_false_path -to {${topmodule}sigma_delta_dac:*}

set_false_path -to $FALSE_OUT
set_false_path -from $FALSE_IN
