##
## PYNQ-Z2 Constraints for Coreographer
## Board: PYNQ-Z2 (xc7z020clg400-1)
##

#==============================================================================
# Clock and Reset
#==============================================================================
# 125 MHz system clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk [get_ports clk]

# Reset button (BTN0)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

#==============================================================================
# LEDs for Debug (LD0-LD3)
#==============================================================================
# Core active indicators
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {core_active[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {core_active[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {core_active[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {core_active[3]}]

#==============================================================================
# RGB LEDs (LD4, LD5) - Optional status indicators
#==============================================================================
# LD4 RGB
# set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports led4_r]
# set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports led4_g]
# set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports led4_b]

# LD5 RGB
# set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports led5_r]
# set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports led5_g]
# set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports led5_b]

#==============================================================================
# Switches (SW0-SW1) - Optional configuration
#==============================================================================
# set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
# set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]

#==============================================================================
# Buttons (BTN0-BTN3)
#==============================================================================
# BTN0 used for reset (see above)
# set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports btn1]
# set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports btn2]
# set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports btn3]

#==============================================================================
# PMOD Connectors - Optional for external debug
#==============================================================================
# PMOD A
# set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {pmoda[0]}]
# set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {pmoda[1]}]
# set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {pmoda[2]}]
# set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {pmoda[3]}]
# set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {pmoda[4]}]
# set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {pmoda[5]}]
# set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {pmoda[6]}]
# set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {pmoda[7]}]

#==============================================================================
# Timing Constraints
#==============================================================================
# Input delay constraints
set_input_delay -clock [get_clocks sys_clk] -min 0.000 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports rst_n]

# Output delay constraints
set_output_delay -clock [get_clocks sys_clk] -min -1.000 [get_ports core_active*]
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports core_active*]

# False paths for async signals (if any)
# set_false_path -from [get_ports rst_n]

#==============================================================================
# Bitstream Configuration
#==============================================================================
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

#==============================================================================
# Additional Constraints for Multi-core Design
#==============================================================================
# Set max delay between cores for neighbor register access
# Adjust based on your topology and timing requirements
# set_max_delay -from [get_cells -hierarchical *core_*] -to [get_cells -hierarchical *core_*] 10.000

# Group related logic together for better placement
# set_property LOC SLICE_X0Y0 [get_cells {core_0_inst}]
# set_property LOC SLICE_X50Y0 [get_cells {core_1_inst}]
