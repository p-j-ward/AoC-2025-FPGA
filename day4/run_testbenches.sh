
# bit_convolution_2d testbench
ghdl -a aoc25_day4_pkg.vhd bit_convolution_2d.vhd test_bit_convolution_2d.vhd
ghdl -e test_bit_convolution_2d 
ghdl -r test_bit_convolution_2d --wave=test_bit_convolution_2d_result.ghw

# conv_count_update_step testbench
ghdl -a --std=08 aoc25_day4_pkg.vhd bit_convolution_2d.vhd conv_count_update_step.vhd test_conv_count_update_step.vhd
ghdl -e --std=08 test_conv_count_update_step
ghdl -r --std=08 test_conv_count_update_step --wave=test_conv_count_update_step_result.ghw

# conv_count_update_pipeline testbench
ghdl -a --std=08 aoc25_day4_pkg.vhd bit_convolution_2d.vhd conv_count_update_step.vhd conv_count_update_pipeline.vhd test_conv_count_update_pipeline.vhd
ghdl -e --std=08 test_conv_count_update_pipeline
ghdl -r --std=08 test_conv_count_update_pipeline --wave=test_conv_count_update_pipeline_result.ghw

# top level testbench, for aoc25_day4_toplevel
ghdl -a --std=08 aoc25_day4_pkg.vhd bit_convolution_2d.vhd conv_count_update_step.vhd conv_count_update_pipeline.vhd simple_dual_port_ram.vhd aoc25_day4_toplevel.vhd test_aoc25_day4_toplevel.vhd
ghdl -e --std=08 test_aoc25_day4_toplevel
ghdl -r --std=08 test_aoc25_day4_toplevel --wave=test_aoc25_day4_toplevel_result.ghw
