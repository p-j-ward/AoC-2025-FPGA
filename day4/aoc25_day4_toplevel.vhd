library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aoc25_day4_toplevel is
    generic (
        DATA_WIDTH  : natural;   -- must be even
        ADDR_WIDTH  : natural;
        COUNT_WIDTH : natural
    );
    port(
        Clk_in       : in  std_logic;

        Start_in     : in  std_logic;
        Num_lines_in : in  unsigned(COUNT_WIDTH-1 downto 0);
        Num_cols_in  : in  unsigned(COUNT_WIDTH-1 downto 0);    -- number of words per line

        -- External memory interface, to data starting at addr 0
        Rd_addr_out  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        Rd_data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        Wr_en_out    : out std_logic;
        Wr_addr_out  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        Wr_data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of aoc25_day4_toplevel is
    -- control signals
    type control_state_t is (IDLE, INIT_CACHES,
                             PREEMPT_START_PASS_1, PREEMPT_START_PASS_2,
                             START_PASS, PASS_IN_PROGRESS, POST_PAD, WAIT_FOR_PIPELINE_DONE);
    signal control_state, control_state_d, control_state_dd : control_state_t := IDLE;
    signal line_idx, col_idx : integer range 0 to 2*ADDR_WIDTH-1; -- line and column indicies, these are used for internal control, and adressing external ram
    signal post_ctr : integer range 0 to 2 + DATA_WIDTH := 0;

    -- input to pipeline, we have three words: left, centre, and right; where
    -- left is from the oldest cache, centre the newest cache, and right the
    -- data currently being read from the external memory - critically the
    -- pipeline depth is equal to DATA_WIDTH, thus the output of the pipeline
    -- will be the updated data coherent with the centre data. we also feed
    -- the right word to the oldest cache at the same time, as that data is
    -- no longer needed
    signal left_word_to_pipeline, centre_word_to_pipeline, right_word_to_pipeline : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal pipeline_dv_in : std_logic := '0';
    signal pipeline_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal pipeline_dv_out   : std_logic;

    -- other pipeline signals, note that count refers to the number of accessible
    -- rolls, which we will accumulate while the pipeline is running
    signal pipeline_srst_n   : std_logic := '0';
    signal pipeline_count_dv : std_logic;
    signal pipeline_count    : unsigned(COUNT_WIDTH-1 downto 0);

    -- cache memory interfaces
    signal cache_a_wr_en, cache_a_wr_en_d, cache_a_wr_en_dd : std_logic := '0';
    signal cache_b_wr_en, cache_b_wr_en_d, cache_b_wr_en_dd : std_logic := '0';
    signal cache_wr_addr_d, cache_wr_addr_dd : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal cache_rd_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal cache_a_wr_data, cache_b_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    --signal cache_a_rd_addr, cache_b_rd_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
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

        Wr_en_in    => cache_a_wr_en, --_d,
        Wr_addr_in  => cache_wr_addr_dd,
        Wr_data_in  => cache_a_wr_data,

        Rd_addr_in  => cache_rd_addr,
        Rd_data_out => cache_a_rd_data
    );

    cache_b_inst : entity work.simple_dual_port_ram
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
        Clk_in      => Clk_in,

        Wr_en_in    => cache_b_wr_en, --_d,
        Wr_addr_in  => cache_wr_addr_dd,
        Wr_data_in  => cache_b_wr_data,

        Rd_addr_in  => cache_rd_addr,
        Rd_data_out => cache_b_rd_data
    );

    -- cache and ext mem read addrs are coherent, thus data is also aligned in pipeline_input_mux_proc
    cache_rd_addr <= std_logic_vector(to_unsigned(line_idx, ADDR_WIDTH));
    Rd_addr_out <= std_logic_vector(to_unsigned(col_idx + to_integer(Num_cols_in)*line_idx, ADDR_WIDTH));

    -- We make passes going down the file, line by line, after each pass we can
    -- move one column across, the sequency for one pass down is as follows:
    --   1. Initialse by zeroing cache a (right) and loading first column (hence
    --      column 1) of input data into cache b (centre).
    --   2. First pass down: input to pipeline is [cache a, cache b, memory]
    --      where memory is the external memory (data column 2 in this case).
    --      Simultaneously we load memory into cache a. The output of the
    --      pipeline for this step will be written back to memory column 1.
    --   3. Second pass down: input to pipeline is [cache b, cache a, memory],
    --      recall cache b contains column 1, cache a contains column 2, and the
    --      pipeline output will be written back to column 2. Simultaneously we
    --      load memory into cache b.
    --   4. Repeat steps 2 and 3, moving one column across the input with each
    --      pass down, and ping-ponging the caches.
    control_proc : process(Clk_in)
    begin
        if rising_edge(Clk_in) then
            case control_state is
                when IDLE =>
                    col_idx  <= 0;
                    line_idx <= 0;
                    post_ctr <= 0;
                    write_to_cache_a_not_b <= '1';
                    if Start_in = '1' then
                        control_state <= INIT_CACHES;
                    end if;

                when INIT_CACHES => -- writes zeros to cache a and mem(col 1) to cache b
                    line_idx <= line_idx + 1;
                    if line_idx = Num_lines_in - 1 then
                        control_state <= START_PASS;
                    end if;

                -- when PREEMPT_START_PASS_1 =>
                --     line_idx <= 0;
                --     col_idx  <= col_idx + 1;
                --     control_state <= PREEMPT_START_PASS_2;

                -- when PREEMPT_START_PASS_2 =>
                --     line_idx <= 0;
                --     control_state <= START_PASS;

                when START_PASS =>  -- adds a line of zero padding at the start
                    line_idx <= 0;
                    col_idx <= 1;
                    control_state <= PASS_IN_PROGRESS;

                when PASS_IN_PROGRESS =>  -- main processing, feeding data into pipeline
                    line_idx <= line_idx + 1;
                    if line_idx = Num_lines_in - 1 then
                        control_state <= POST_PAD;
                    end if;

                when POST_PAD => -- add 1 + pipeline depth zero padding at the end, recall pipeline depth is DATA_WIDTH
                    post_ctr <= post_ctr + 1;
                    if post_ctr >= 1 + DATA_WIDTH then
                        control_state <= WAIT_FOR_PIPELINE_DONE;
                    end if;

                when WAIT_FOR_PIPELINE_DONE =>
                    if pipeline_dv_out = '0' then
                        control_state <= IDLE;  -- for test only, let's see how this goes......
                    end if;

                when others => null;
            end case;

            control_state_d <= control_state;
            control_state_dd <= control_state_d;
        end if;
    end process;

    cache_input_mux_proc : process(Clk_in)
    begin
        if rising_edge(Clk_in) then
            case control_state_d is
                when INIT_CACHES =>
                    cache_a_wr_data <= (others => '0');
                    cache_b_wr_data <= Rd_data_in;
                    cache_a_wr_en <= '1';
                    cache_b_wr_en <= '1';

                when PASS_IN_PROGRESS =>
                    if write_to_cache_a_not_b = '1' then
                        cache_a_wr_data <= Rd_data_in;
                        cache_b_wr_data <= (others => '0');
                        cache_a_wr_en <= '1';
                        cache_b_wr_en <= '0';
                    else
                        cache_a_wr_data <= (others => '0');
                        cache_b_wr_data <= Rd_data_in;
                        cache_a_wr_en <= '0';
                        cache_b_wr_en <= '1';
                    end if;

                when others =>
                    cache_a_wr_data <= (others => '0');
                    cache_b_wr_data <= (others => '0');
                    cache_a_wr_en <= '0';
                    cache_b_wr_en <= '0';
            end case;

            -- -- account for 2 cycles of delay, for ram+mux
            -- cache_a_wr_en_d  <= cache_a_wr_en;
            -- cache_a_wr_en_dd <= cache_a_wr_en_d;
            -- cache_b_wr_en_d  <= cache_b_wr_en;
            -- cache_b_wr_en_dd <= cache_b_wr_en_d;
            cache_wr_addr_d <= std_logic_vector(to_unsigned(line_idx, ADDR_WIDTH));
            cache_wr_addr_dd <= cache_wr_addr_d;
        end if;
    end process;

    pipeline_input_mux_proc : process(Clk_in)
    begin
        if rising_edge(Clk_in) then
            case control_state_d is
                when PASS_IN_PROGRESS =>
                    if write_to_cache_a_not_b = '1' then
                        -- writing to cache a means cache a is older, i.e. left
                        left_word_to_pipeline   <= cache_a_rd_data;
                        centre_word_to_pipeline <= cache_b_rd_data;
                    else
                        -- and vice versa
                        left_word_to_pipeline   <= cache_b_rd_data;
                        centre_word_to_pipeline <= cache_a_rd_data;
                    end if;
                    right_word_to_pipeline  <= Rd_data_in;
                    pipeline_dv_in <= '1';

                when START_PASS | POST_PAD =>
                    left_word_to_pipeline   <= (others => '0');
                    centre_word_to_pipeline <= (others => '0');
                    right_word_to_pipeline  <= (others => '0');
                    pipeline_dv_in <= '1';

                when others =>
                    left_word_to_pipeline   <= (others => '0');
                    centre_word_to_pipeline <= (others => '0');
                    right_word_to_pipeline  <= (others => '0');
                    pipeline_dv_in <= '0';
            end case;
        end if;
    end process;




end architecture;