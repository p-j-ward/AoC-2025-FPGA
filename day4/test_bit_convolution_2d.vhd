-- Testbench for bit_convolution_2d
-- Uses AoC example input .......
--
-- To run this testbench, with a terminal in day4 directory, run:
--   ghdl -a bit_convolution_2d.vhd test_bit_convolution_2d.vhd
--   ghdl -e test_bit_convolution_2d 
--   ghdl -r test_bit_convolution_2d --wave=wave.ghw   
--
library ieee;
use ieee.std_logic_1164.all;

library std;
use std.textio.all;

entity test_bit_convolution_2d is
end entity;

architecture testbench of test_bit_convolution_2d is
    constant T_WAIT : time := 1 ns;
    constant DATA_WIDTH : natural := 10;
    constant BUS_WIDTH  : natural := DATA_WIDTH+2;  -- note padding on either side

    -- input parsing function
    function parse_input_line(STR : string) return std_logic_vector is
        variable ret_val : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        for i in 0 to DATA_WIDTH-1 loop
            if STR(i+1) = '@' then ret_val(i) := '1'; else ret_val(i) := '0'; end if;
        end loop;
        return ret_val;
    end function;

    -- signals for dut
    signal clk, srst_n, bus_dv_in : std_logic := '0';
    signal bus_dv_out : std_logic;
    signal bus_in  : std_logic_vector(BUS_WIDTH-1 downto 0) := (others => '0');
    signal bus_out : std_logic_vector(BUS_WIDTH-3 downto 0);

    -- for part 1 solution, count up bits while running
    signal acc : natural := 0;
    signal reset_acc : std_logic := '0';
    
    function count_bits(VEC_IN : std_logic_vector) return natural is
        variable count : natural := 0;
    begin
        for i in VEC_IN'range loop
            if VEC_IN(i) = '1' then count := count + 1; end if;
        end loop;
        return count;
    end function;
begin
    dut : entity work.bit_convolution_2d
    generic map (
        BUS_IN_WIDTH => BUS_WIDTH
    )
    port map (
        Clk_in     => clk,
        Srst_n_in  => srst_n,
        Bus_dv_in  => bus_dv_in,
        Bus_dv_out => bus_dv_out,
        Bus_in     => bus_in,
        Bus_out    => bus_out
    );

    stimulus_proc : process
        file F_in : text open read_mode is "day4_input_example.txt";
        variable f_line : line;
        variable line_as_string : string (1 to DATA_WIDTH);
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

        while not endfile(F_in) loop
            clk <= '1';
            wait for 0 ns;
            readline(F_in, f_line);
            read(f_line, line_as_string);
            bus_in <= '0' & parse_input_line(line_as_string) & '0'; -- note padding either side
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

        -- --
        -- -- second test: non-contiguous data
        -- --
        -- clk <= '0';
        -- srst_n <= '0'; bus_dv_in <= '0';
        -- wait for T_WAIT;
        -- clk <= '1';
        -- wait for T_WAIT;
        -- clk <= '0';
        -- wait for T_WAIT;

        -- -- first cycle, first line padding
        -- clk <= '1';
        -- wait for 0 ns;
        -- srst_n <= '1'; bus_dv_in <= '1';
        -- wait for T_WAIT;
        -- clk <= '0';
        -- wait for T_WAIT;

        -- -- stall a cycle
        -- clk <= '1';
        -- wait for T_WAIT;
        -- clk <= '0';
        -- wait for T_WAIT;

        -- -- add 2 cycles of input

        wait;
    end process;

    -- accumulate number of set bits, to give part 1 solution
    part1_acc_proc : process(clk)
    begin
        if rising_edge(clk) then
            if bus_dv_out = '1' then
                acc <= acc + count_bits(bus_out);
            end if;
            if reset_acc = '1' then
                acc <= 0;
            end if;
        end if;
    end process;

end architecture;