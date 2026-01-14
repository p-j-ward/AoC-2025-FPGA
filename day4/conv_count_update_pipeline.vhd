library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aoc25_day4_pkg.all;

entity conv_count_update_pipeline is
    generic (
        PIPELINE_DEPTH : natural;
        BUS_OUT_WIDTH  : natural;
        COUNT_WIDTH    : natural
    );
    port (
        Clk_in     : in  std_logic;
        Srst_n_in  : in  std_logic;

        Bus_dv_in  : in  std_logic;
        Bus_in     : in  std_logic_vector(BUS_OUT_WIDTH+2*PIPELINE_DEPTH-1 downto 0);
        Bus_dv_out : out std_logic;
        Bus_out    : out std_logic_vector(BUS_OUT_WIDTH-1 downto 0);

        -- Accumulates count along the pipeline
        Count_in   : in  unsigned(COUNT_WIDTH-1 downto 0);
        Count_out  : out unsigned(COUNT_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of conv_count_update_pipeline is
    -- note, only the full width of this array is used for the first output, as
    -- the bus narrows along the pipeline, we'll always index starting at bit 0
    type data_arr_t is array (0 to PIPELINE_DEPTH-1) of std_logic_vector(BUS_OUT_WIDTH+2*PIPELINE_DEPTH-3 downto 0);
    signal data   : data_arr_t := (others => (others => '0'));
    type count_arr_t is array (0 to PIPELINE_DEPTH-1) of unsigned(COUNT_WIDTH-1 downto 0);
    signal count : count_arr_t := (others => (others => '0'));
    signal bus_dv : std_logic_vector(PIPELINE_DEPTH-1 downto 0) := (others => '0');
begin
    pipeline_stage_0 : entity work.conv_count_update_step
    generic map (
        BUS_IN_WIDTH => BUS_OUT_WIDTH+2*PIPELINE_DEPTH,
        COUNT_WIDTH  => COUNT_WIDTH
    )
    port map (
        Clk_in     => Clk_in,
        Srst_n_in  => Srst_n_in,
        Bus_dv_in  => Bus_dv_in,
        Bus_in     => Bus_in,
        Bus_dv_out => bus_dv(0),
        Bus_out    => data(0),
        Count_in   => Count_in,
        Count_out  => count(0)
    );

    pipeline_gen : for i in 1 to PIPELINE_DEPTH-1 generate
        pipeline_stage_i : entity work.conv_count_update_step
        generic map (
            BUS_IN_WIDTH => BUS_OUT_WIDTH+2*(PIPELINE_DEPTH-i),
            COUNT_WIDTH  => COUNT_WIDTH
        )
        port map (
            Clk_in     => Clk_in,
            Srst_n_in  => Srst_n_in,
            Bus_dv_in  => bus_dv(i-1),
            Bus_in     => data(i-1)(BUS_OUT_WIDTH+2*(PIPELINE_DEPTH-i)-1 downto 0),
            Bus_dv_out => bus_dv(i),
            Bus_out    => data(i)(BUS_OUT_WIDTH+2*(PIPELINE_DEPTH-i)-3 downto 0),
            Count_in   => count(i-1),
            Count_out  => count(i)
        );
    end generate;

    Bus_out <= data(PIPELINE_DEPTH-1)(BUS_OUT_WIDTH-1 downto 0);
    Count_out <= count(PIPELINE_DEPTH-1);
    Bus_dv_out <= bus_dv(PIPELINE_DEPTH-1);

end architecture;