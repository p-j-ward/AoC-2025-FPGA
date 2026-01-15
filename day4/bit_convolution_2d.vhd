-- 2D convolution, applying a 3x3 kernel, which is a function
-- of std_logic_vector -> std_logic, in this case 'less_than_eq_n_bits_set'.
-- We take a parallel bus which is one dimension of the convolution,
-- and ingest it one step at a time, which is the second dimension.
library ieee;
use ieee.std_logic_1164.all;

use work.aoc25_day4_pkg.all;

entity bit_convolution_2d is
    generic (
        DATA_IN_WIDTH    : natural;
        PRESERVE_PREPAD  : boolean := false
    );
    port (
        Clk_in    : in  std_logic;
        Srst_n_in : in  std_logic;

        Dv_in     : in  std_logic;
        Data_in   : in  std_logic_vector(DATA_IN_WIDTH-1 downto 0);
        
        Dv_out    : out std_logic;
        Data_out  : out std_logic_vector(DATA_IN_WIDTH-1 downto 0); -- if needed, input data delayed to give the input line for the current output
        Conv_out  : out std_logic_vector(DATA_IN_WIDTH-3 downto 0)
    );
end entity;

architecture rtl of bit_convolution_2d is
    -- pipeline registers for 3 rows of input
    signal bus_reg, bus_reg_d, bus_reg_dd : std_logic_vector(DATA_IN_WIDTH-1 downto 0) := (others => '0');
    signal reg_dv_pipe   : std_logic_vector(2 downto 0) := (others => '0');
    signal output_dv_int : std_logic := '0';

    -- a view of the pipeline an row of overlapping 3x3 squares, the inputs to the kernel function
    type conv_window_t is array (0 to 2) of std_logic_vector(2 downto 0);
    type conv_window_arr_t is array (natural range <>) of conv_window_t;
    signal conv_kernel_inputs : conv_window_arr_t(DATA_IN_WIDTH-1 downto 0);
    signal conv_kernel_outputs : std_logic_vector(DATA_IN_WIDTH-3 downto 0) := (others => '0');

    -- convolution kernel for our problem - rule is: middle bit must be set,
    -- and 4 or fewer of the surrouding bits set, for output high
    function conv_kernel(WINDOW_IN : conv_window_t) return std_logic is
        variable neighbours_vec : std_logic_vector(7 downto 0);
        variable ret_bit : std_logic;
    begin
        neighbours_vec := WINDOW_IN(0) & WINDOW_IN(1)(0) & WINDOW_IN(1)(2) & WINDOW_IN(2);
        ret_bit := WINDOW_IN(1)(1) and less_than_n_bits_set(neighbours_vec, 4);
        return ret_bit;
    end function;
begin
    pipeline_reg_proc : process (Clk_in)
    begin
        if rising_edge(Clk_in) then
            output_dv_int <= '0';

            if Srst_n_in = '0' then
                bus_reg    <= (others => '0');
                bus_reg_d  <= (others => '0');
                bus_reg_dd <= (others => '0');
                reg_dv_pipe <= (others => '0');
            else
                if Dv_in = '1' then
                    bus_reg    <= Data_in;
                    bus_reg_d  <= bus_reg;
                    bus_reg_dd <= bus_reg_d;
                    reg_dv_pipe <= reg_dv_pipe(1 downto 0) & '1';

                    -- once pipeline is full, dv in will result in dv out,
                    -- delayed by 1 cycle, hence checking only lower two
                    -- bits, to 'preempt' the first cycle that's full
                    if reg_dv_pipe(1 downto 0) = b"11" then
                        output_dv_int <= '1';
                    end if;
                    if PRESERVE_PREPAD = true and reg_dv_pipe(0) = '1' then
                        output_dv_int <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;


    apply_kernel_gen : for i in 0 to DATA_IN_WIDTH-3 generate
        -- pipeline viewed as inputs to the convolution kernel, this is really just renaming wires
        conv_kernel_inputs(i) <= (
            0 => bus_reg(i+2 downto i),
            1 => bus_reg_d(i+2 downto i),
            2 => bus_reg_dd(i+2 downto i)
        );

        -- finally, apply the kernel across the bus
        conv_kernel_outputs(i) <= conv_kernel(conv_kernel_inputs(i));
    end generate;

    -- could pipeline here, currently just combinatorial
    Dv_out   <= output_dv_int;
    Data_out <= bus_reg_d;
    Conv_out <= conv_kernel_outputs;
end architecture;