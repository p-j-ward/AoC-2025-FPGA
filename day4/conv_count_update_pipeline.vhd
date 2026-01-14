library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aoc25_day4_pkg.all;

entity conv_count_update_pipeline is
    generic (
        PIPELINE_DEPTH : natural;
        DATA_IN_WIDTH  : natural;
        COUNT_WIDTH    : natural
    );
    port (
        Clk_in    : in  std_logic;
        Srst_n_in : in  std_logic;

        Dv_in     : in  std_logic;
        Count_in  : in  unsigned(COUNT_WIDTH-1 downto 0);
        Data_in   : in  std_logic_vector(DATA_IN_WIDTH-1 downto 0);

        Dv_out    : out std_logic;
        Data_out  : out std_logic_vector(DATA_IN_WIDTH-2*PIPELINE_DEPTH-1 downto 0);
        Count_out : out unsigned(COUNT_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of conv_count_update_pipeline is
    -- note, only the full width of this array is used for the first output, as
    -- the bus narrows along the pipeline, we'll always index starting at bit 0
    type data_arr_t is array (0 to PIPELINE_DEPTH-1) of std_logic_vector(DATA_IN_WIDTH-3 downto 0);
    signal data   : data_arr_t := (others => (others => '0'));
    type count_arr_t is array (0 to PIPELINE_DEPTH-1) of unsigned(COUNT_WIDTH-1 downto 0);
    signal count : count_arr_t := (others => (others => '0'));
    signal bus_dv : std_logic_vector(PIPELINE_DEPTH-1 downto 0) := (others => '0');
begin
    pipeline_stage_0 : entity work.conv_count_update_step
    generic map (
        DATA_IN_WIDTH => DATA_IN_WIDTH,
        COUNT_WIDTH   => COUNT_WIDTH
    )
    port map (
        Clk_in    => Clk_in,
        Srst_n_in => Srst_n_in,

        Dv_in     => Dv_in,
        Data_in   => Data_in,
        Count_in  => Count_in,

        Dv_out    => bus_dv(0),
        Data_out  => data(0),
        Count_out => count(0)
    );

    pipeline_gen : for i in 1 to PIPELINE_DEPTH-1 generate
        pipeline_stage_i : entity work.conv_count_update_step
        generic map (
            DATA_IN_WIDTH => DATA_IN_WIDTH-2*i,
            COUNT_WIDTH   => COUNT_WIDTH
        )
        port map (
            Clk_in    => Clk_in,
            Srst_n_in => Srst_n_in,

            Dv_in     => Dv_in, --bus_dv(i-1), .... using global dv in is crazy but might just work
            Data_in   => data(i-1)(DATA_IN_WIDTH-2*i-1 downto 0),
            Count_in  => count(i-1),

            Dv_out    => bus_dv(i),
            Data_out  => data(i)(DATA_IN_WIDTH-2*i-3 downto 0),
            Count_out => count(i)
        );
    end generate;

    Data_out <= data(PIPELINE_DEPTH-1)(DATA_IN_WIDTH-2*PIPELINE_DEPTH-1 downto 0);
    Count_out <= count(PIPELINE_DEPTH-1);
    Dv_out <= bus_dv(PIPELINE_DEPTH-1);

end architecture;