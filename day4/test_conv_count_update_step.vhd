-- Testbench for conv_count_update_step
--
-- To run this testbench, with a terminal in day4 directory, run:
--   ghdl -a aoc25_day4_pkg.vhd bit_convolution_2d.vhd conv_count_update_step.vhd test_conv_count_update_step.vhd
--   ghdl -e test_conv_count_update_step
--   ghdl -r test_conv_count_update_step --wave=wave.ghw   
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.aoc25_day4_pkg.all;

entity test_conv_count_update_step is
end entity;

architecture testbench of test_conv_count_update_step is
    constant T_WAIT : time := 1 ns;
    constant DATA_WIDTH : natural := 10;
    constant BUS_WIDTH  : natural := DATA_WIDTH+2;  -- note padding on either side

    -- parsed data from input file
    constant NUM_INPUT_LINES : natural := 10;
    type input_data_t is array (0 to NUM_INPUT_LINES-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal input_data : input_data_t;

    -- signals for dut
    signal clk, srst_n, bus_dv_in : std_logic := '0';
    signal bus_dv_out : std_logic;
    signal bus_in  : std_logic_vector(BUS_WIDTH-1 downto 0) := (others => '0');
    signal bus_out : std_logic_vector(BUS_WIDTH-3 downto 0);
    signal count_out : unsigned(15 downto 0);

    -- for part 1 solution, count up bits while running
    signal acc : natural := 0;
    signal reset_acc : std_logic := '0';
begin
    -- testing a single instance, this produces similar waveforms to test_bit_convolution_2d
    dut : entity work.conv_count_update_step
    generic map (
        BUS_IN_WIDTH => BUS_WIDTH
    )
    port map (
        Clk_in     => clk,
        Srst_n_in  => srst_n,
        Bus_dv_in  => bus_dv_in,
        Bus_in     => bus_in,
        Bus_dv_out => bus_dv_out,
        Bus_out    => bus_out,
        Count_in   => (others => '0'),
        Count_out  => count_out
    );

    -- pipeline test: 10 stages deep to replicate part2 example
    -- each stage of pipeline increases bus width by 2, due to
    -- padding either side
    pipeline_stage_0 : entity work.conv_count_update_step
    generic map (
        BUS_IN_WIDTH => BUS_WIDTH + 20
    )
    port map (
        Clk_in     => clk,
        Srst_n_in  => srst_n,
        Bus_dv_in  => bus_dv_in,
        Bus_in     => bus_in,
        Bus_dv_out => bus_dv_out,
        Bus_out    => bus_out,
        Count_in   => (others => '0'),
        Count_out  => count_out
    );

    pipeline_gen : for i in 1 to 9 generate
        pipeline_stage_i : entity work.conv_count_update_step
        generic map (
            BUS_IN_WIDTH => BUS_WIDTH + 18
        )
        port map (
            Clk_in     => clk,
            Srst_n_in  => srst_n,
            Bus_dv_in  => bus_dv_in,
            Bus_in()     => bus_in,   -- bus_in already has 2 bits padding
            Bus_dv_out => bus_dv_out,
            Bus_out    => bus_out,
            Count_in   => 
            Count_out  => count_out
        );
    end generate;

    read_file_proc : process
        file F_in : text open read_mode is "day4_input_example.txt";
        variable f_line : line;
        variable line_as_string : string (1 to DATA_WIDTH);
    begin
        for i in input_data'range loop
            readline(F_in, f_line);
            read(f_line, line_as_string);
            input_data(i) <= parse_input_line(line_as_string, DATA_WIDTH);
        end loop;
        wait;
    end process;

    -- test stimulus, as per test_bit_convolution_2d
    stimulus_proc : process
    begin
        --
        -- first test: contiguous data stream
        --
        clk <= '0';
        srst_n <= '0'; bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- first cycle, first line padding
        clk <= '1';
        wait for 0 ns;
        srst_n <= '1'; bus_dv_in <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        for i in input_data'range loop
            clk <= '1';
            wait for 0 ns;
            bus_in <= '0' & input_data(i) & '0'; -- note padding either side
            wait for T_WAIT;
            clk <= '0';
            wait for T_WAIT;
        end loop;

        -- final cycle of padding
        clk <= '1';
        wait for 0 ns;
        bus_in <= (others => '0');
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- done
        clk <= '1';
        wait for 0 ns;
        srst_n <= '0'; bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        reset_acc <= '1';
        wait for T_WAIT;
        clk <= '0';
        reset_acc <= '0';

        --
        -- second test: non-contiguous data
        --
        clk <= '0';
        srst_n <= '0'; bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- first cycle, first line padding
        clk <= '1';
        wait for 0 ns;
        srst_n <= '1'; bus_dv_in <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- stall a cycle
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- add 2 cycles of input
        for i in 0 to 1 loop
            clk <= '1';
            wait for 0 ns;
            bus_dv_in <= '1';
            bus_in <= '0' & input_data(i) & '0'; -- note padding either side
            wait for T_WAIT;
            clk <= '0';
            wait for T_WAIT;
        end loop;

        -- stall a cycle
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- add 4 cycles of input
        for i in 2 to 5 loop
            clk <= '1';
            wait for 0 ns;
            bus_dv_in <= '1';
            bus_in <= '0' & input_data(i) & '0'; -- note padding either side
            wait for T_WAIT;
            clk <= '0';
            wait for T_WAIT;
        end loop;

        -- stall 2 cycles
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- add 3 cycles of input
        for i in 6 to 8 loop
            clk <= '1';
            wait for 0 ns;
            bus_dv_in <= '1';
            bus_in <= '0' & input_data(i) & '0'; -- note padding either side
            wait for T_WAIT;
            clk <= '0';
            wait for T_WAIT;
        end loop;

        -- stall a cycle
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- add last cycle of input
        for i in 9 to 9 loop
            clk <= '1';
            wait for 0 ns;
            bus_dv_in <= '1';
            bus_in <= '0' & input_data(i) & '0'; -- note padding either side
            wait for T_WAIT;
            clk <= '0';
            wait for T_WAIT;
        end loop;

        -- stall 3 cycles
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- final cycle of padding
        clk <= '1';
        wait for 0 ns;
        bus_dv_in <= '1';
        bus_in <= (others => '0');
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;

        -- done
        clk <= '1';
        wait for 0 ns;
        srst_n <= '0'; bus_dv_in <= '0';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        wait for T_WAIT;
        clk <= '0';
        wait for T_WAIT;
        clk <= '1';
        reset_acc <= '1';
        wait for T_WAIT;
        clk <= '0';
        reset_acc <= '0';

        wait;
    end process;

end architecture;