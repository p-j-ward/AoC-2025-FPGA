-- Top level testbench for aoc25_day4_toplevel
--
-- To run this testbench, with a terminal in day4 directory, run:
--   ghdl -a --std=08 aoc25_day4_pkg.vhd bit_convolution_2d.vhd conv_count_update_step.vhd conv_count_update_pipeline.vhd simple_dual_port_ram.vhd aoc25_day4_toplevel.vhd test_aoc25_day4_toplevel.vhd
--   ghdl -e --std=08 test_aoc25_day4_toplevel
--   ghdl -r --std=08 test_aoc25_day4_toplevel --wave=test_aoc25_day4_toplevel.ghw
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.aoc25_day4_pkg.all;

entity test_aoc25_day4_toplevel is
end entity;

architecture testbench of test_aoc25_day4_toplevel is
    -- clock
    constant NUM_SIM_CYCLES : natural := 100;
    constant T_WAIT : time := 1 ns;
    signal clk : std_logic := '0';

    -- signals for dut
    constant DATA_WIDTH : natural := 4;
    constant ADDR_WIDTH : natural := 8;
    signal rd_addr_out, wr_addr_out : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal rd_data_in,  wr_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal wr_en_out : std_logic;

    signal start : std_logic := '0';
begin
    dut : entity work.aoc25_day4_toplevel
    generic map (
        DATA_WIDTH  => DATA_WIDTH,
        ADDR_WIDTH  => ADDR_WIDTH,
        COUNT_WIDTH => 16
    )
    port map (
        Clk_in       => clk,

        Start_in     => start,
        Num_lines_in => x"000A",
        Num_cols_in  => x"000A",

        -- External memory interface, to data starting at addr 0
        Rd_addr_out  => rd_addr_out,
        Rd_data_in   => rd_data_in,
        Wr_en_out    => wr_en_out,
        Wr_addr_out  => wr_addr_out,
        Wr_data_out  => wr_data_out
    );

    clock_proc : process
    begin
        for i in 1 to NUM_SIM_CYCLES loop
            clk <= '0';
            wait for T_WAIT;
            clk <= '1';
            wait for T_WAIT;
        end loop;
        wait;
    end process;

    start <= '1' after 10*T_WAIT, '0' after 12*T_WAIT;

end architecture;