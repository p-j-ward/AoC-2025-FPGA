library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aoc25_day4_toplevel is
    generic (
        DATA_WIDTH  : integer;   -- must be even
        ADDR_WIDTH  : integer;
        COUNT_WIDTH : integer
    );
    port(
        Clk_in      : in  std_logic;

        Start_in    : in  std_logic;

        -- External memory interface, to data starting at addr 0
        Wr_en_in    : in  std_logic;
        Wr_addr_in  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        Wr_data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        Rd_addr_in  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        Rd_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of aoc25_day4_toplevel is
    -- input to pipeline, we have three words: left, centre, and right; where
    -- left is from the oldest cache, centre the newest cache, and right the
    -- data currently being read from the external memory - critically the
    -- pipeline depth is equal to DATA_WIDTH, thus the output of the pipeline
    -- will be the updated data coherent with the centre data. we also feed
    -- the right word to the oldest cache at the same time, as that data is
    -- no longer needed
    signal left_word_to_pipeline, centre_word_to_pipeline, right_word_to_pipeline : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal pipeline_dv_in    : std_logic := '0';
    signal pipeline_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal pipeline_dv_out   : std_logic;

    -- other pipeline signals, note that count refers to the number of accessible
    -- rolls, which we will accumulate while the pipeline is running
    signal pipeline_srst_n   : std_logic := '0';
    signal pipeline_count_dv : std_logic;
    signal pipeline_count    : unsigned(COUNT_WIDTH-1 downto 0);

    -- cache memory interfaces
    signal cache_a_wr_en,   cache_b_wr_en   : std_logic := '0';
    signal cache_a_wr_addr, cache_b_wr_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal cache_a_wr_data, cache_b_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal cache_a_rd_addr, cache_b_rd_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal cache_a_rd_data, cache_b_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal write_to_cache_a_not_b : std_logic := '0';   -- when this is high, cache a is oldest, when low, cache b is oldest
begin

    pipeline_inst : entity work.conv_count_update_pipeline
    generic map (
        PIPELINE_DEPTH => DATA_WIDTH,
        DATA_IN_WIDTH  => DATA_WIDTH*3,
        COUNT_WIDTH    => COUNT_WIDTH
    )
    port map (
        Clk_in       => Clk_in,
        Srst_n_in    => pipeline_srst_n,

        Dv_in        => pipeline_dv_in,
        Data_in      => (left_word_to_pipeline & centre_word_to_pipeline & right_word_to_pipeline),

        Data_dv_out  => pipeline_dv_out,
        Data_out     => pipeline_data_out,
        Count_dv_out => pipeline_count_dv,
        Count_out    => pipeline_count
    );

    cache_a_inst : entity work.simple_dual_port_ram
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
        Clk_in      => Clk_in,

        Wr_en_in    => cache_a_wr_en,
        Wr_addr_in  => cache_a_wr_addr,
        Wr_data_in  => cache_a_wr_data,

        Rd_addr_in  => cache_a_rd_addr,
        Rd_data_out => cache_a_rd_data
    );

    cache_b_inst : entity work.simple_dual_port_ram
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
        Clk_in      => Clk_in,

        Wr_en_in    => cache_b_wr_en,
        Wr_addr_in  => cache_b_wr_addr,
        Wr_data_in  => cache_b_wr_data,

        Rd_addr_in  => cache_b_rd_addr,
        Rd_data_out => cache_b_rd_data
    );

end architecture;