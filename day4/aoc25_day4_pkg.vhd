-- Helper functions of AoC 2025 Day 4
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package aoc25_day4_pkg is
    function less_than_n_bits_set(VEC : std_logic_vector; N : natural) return std_logic;
    function count_bits(VEC_IN : std_logic_vector) return natural;

    -- for testbench only: file input parsing function
    function parse_input_line(STR : string; DATA_WIDTH : natural) return std_logic_vector;
end package;

package body aoc25_day4_pkg is

    function less_than_n_bits_set(VEC : std_logic_vector; N : natural) return std_logic is
        variable count : natural := 0;
        variable ret_bit : std_logic;
    begin
        -- sum number of bits set in VEC
        for i in VEC'range loop
            if VEC(i) = '1' then
                count := count + 1;
            end if;
        end loop;

        if count < N then ret_bit := '1'; else ret_bit := '0';
        end if;
        return ret_bit;
    end function;

    function count_bits(VEC_IN : std_logic_vector) return natural is
        variable count : natural := 0;
    begin
        for i in VEC_IN'range loop
            if VEC_IN(i) = '1' then count := count + 1; end if;
        end loop;
        return count;
    end function;

    -- for testbench only: file input parsing function
    function parse_input_line(STR : string; DATA_WIDTH : natural) return std_logic_vector is
        variable ret_val : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        for i in 0 to DATA_WIDTH-1 loop
            if STR(i+1) = '@' then ret_val(i) := '1'; else ret_val(i) := '0'; end if;
        end loop;
        return ret_val;
    end function;

end package body;