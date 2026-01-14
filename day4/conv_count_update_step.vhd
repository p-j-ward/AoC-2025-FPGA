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
        BUS_IN_WIDTH : natural;
        COUNT_WIDTH  : natural
    );
    port (
        Clk_in     : in  std_logic;
        Srst_n_in  : in  std_logic;

        Bus_dv_in  : in  std_logic;
        Bus_in     : in  std_logic_vector(BUS_IN_WIDTH-1 downto 0) := (others => '0');  -- initialise to zero to automatically add padding, to make generating long pipelines easier
        Bus_dv_out : out std_logic;
        Bus_out    : out std_logic_vector(BUS_IN_WIDTH-3 downto 0);

        -- Accumulates count along the pipeline
        Count_in   : in  unsigned(COUNT_WIDTH-1 downto 0);
        Count_out  : out unsigned(COUNT_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of conv_count_update_step is
    -- first stage outputs
    signal bus_dv_from_conv  : std_logic := '0';
    signal bus_out_from_conv : std_logic_vector(BUS_IN_WIDTH-3 downto 0);
    signal bus_dly_from_conv : std_logic_vector(BUS_IN_WIDTH-1 downto 0);
begin
    bit_convolution_2d_inst : entity work.bit_convolution_2d
    generic map (
        BUS_IN_WIDTH => BUS_IN_WIDTH
    )
    port map (
        Clk_in      => Clk_in,
        Srst_n_in   => Srst_n_in,

        Bus_dv_in   => Bus_dv_in,
        Bus_in      => Bus_in,

        Bus_dv_out  => bus_dv_from_conv,
        Bus_out     => bus_out_from_conv,
        Bus_dly_out => bus_dly_from_conv
    );

    -- second step of computation, count 1's on bus_out_from_conv and update
    count_accumulate_update : process (Clk_in)
    begin
        if rising_edge(Clk_in) then
            if Srst_n_in = '0' then
                Count_out <= (others => '0');
                Bus_out <= (others => '0');
                Bus_dv_out <= '0';
            else
                Count_out <= Count_in + to_unsigned(count_bits(bus_out_from_conv), Count_out'length);
                Bus_out <= bus_dly_from_conv(BUS_IN_WIDTH-2 downto 1) and (not bus_out_from_conv);
                Bus_dv_out <= bus_dv_from_conv;
            end if;
        end if;
    end process;
end architecture;