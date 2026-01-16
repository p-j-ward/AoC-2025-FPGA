-- This component represents a single full step of computation, first applying
-- bit convolution to the input, which results in a bus representing the
-- accesible rolls, this is the counted and passed to the updater which results
-- in the next iteration of computation. Due to the bit convolution, the width
-- reduces by 2 when passing through this block.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aoc25_day4_pkg.all;

entity conv_count_update_step is
    generic (
        DATA_IN_WIDTH : natural;
        COUNT_WIDTH   : natural;
        COUNT_MASK    : std_logic_vector(DATA_IN_WIDTH-3 downto 0) := (others => '1') -- in pipelines we may or may not want to exclude certain bits from the count
    );
    port (
        Clk_in       : in  std_logic;
        Srst_n_in    : in  std_logic;

        Data_dv_in   : in  std_logic;
        Data_in      : in  std_logic_vector(DATA_IN_WIDTH-1 downto 0);
        Count_dv_in  : in  std_logic;
        Count_in     : in  unsigned(COUNT_WIDTH-1 downto 0);

        Data_dv_out  : out std_logic;
        Data_out     : out std_logic_vector(DATA_IN_WIDTH-3 downto 0);
        Count_dv_out : out std_logic;
        Count_out    : out unsigned(COUNT_WIDTH-1 downto 0)   -- ...as things stand at the minute, count propagates faster than data
    );
end entity;

architecture rtl of conv_count_update_step is
    -- first stage outputs
    signal bus_dv_from_conv : std_logic := '0';
    signal accessible_rolls : std_logic_vector(DATA_IN_WIDTH-3 downto 0);
    signal delayed_data     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
begin
    bit_convolution_2d_inst : entity work.bit_convolution_2d
    generic map (
        DATA_IN_WIDTH => DATA_IN_WIDTH,
        PRESERVE_PREPAD => true
    )
    port map (
        Clk_in    => Clk_in,
        Srst_n_in => Srst_n_in,

        Dv_in     => Data_dv_in,
        Data_in   => Data_in,

        Dv_out    => bus_dv_from_conv,
        Conv_out  => accessible_rolls,
        Data_out  => delayed_data
    );

    -- second step of computation, count 1's on accessible_rolls and update
    count_accumulate_update : process (Clk_in)
    begin
        if rising_edge(Clk_in) then
            Count_dv_out <= Count_dv_in;

            if Srst_n_in = '0' then
                Count_out <= (others => '0');
                Data_out <= (others => '0');
                Data_dv_out <= '0';
                Count_dv_out <= '0';
            else
                Data_dv_out <= bus_dv_from_conv;
                Count_out   <= Count_in + to_unsigned(count_bits(accessible_rolls and COUNT_MASK), Count_out'length);
                Data_out    <= delayed_data(DATA_IN_WIDTH-2 downto 1) and (not accessible_rolls);
            end if;
        end if;
    end process;
end architecture;