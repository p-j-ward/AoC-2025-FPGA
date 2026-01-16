library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_dual_port_ram is
    generic (
        DATA_WIDTH : integer;
        ADDR_WIDTH : integer
    );
    port (
        Clk_in      : in  std_logic;

        Wr_en_in    : in  std_logic;
        Wr_addr_in  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        Wr_data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        Rd_addr_in  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        Rd_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of simple_dual_port_ram is
    type ram_arr_t is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    --signal ram : ram_arr_t := (others => (others => '0'));
    -- test only
    --signal ram : ram_arr_t := (0 => x"0", 1 => x"1", 2 => x"2", 3 => x"3", 4 => x"4", 5 => x"5", 6 => x"6", 7 => x"7", 8 => x"8", 9 => x"9", 10 => x"A", 11 => x"B", 12 => x"C", 13 => x"D", 14 => x"E", 15 => x"F", others => (others => '0'));
    signal ram : ram_arr_t := (
    0 => x"3",  1 => x"7",  2 => x"8", 3 => x"E",   4 => x"A",  5 => x"C", 
    6 => x"F",  7 => x"A",  8 => x"C", 9 => x"B",   10 => x"C", 11 => x"8", 
    12 => x"D", 13 => x"E", 14 => x"C", 15 => x"7", 16 => x"F", 17 => x"4", 
    18 => x"5", 19 => x"5", 20 => x"C", 21 => x"B", 22 => x"B", 23 => x"C", 
    24 => x"7", 25 => x"F", 26 => x"8", 27 => x"A", 28 => x"E", 29 => x"8", others => x"0");
begin
    ram_proc : process (Clk_in)
    begin
        if rising_edge(Clk_in) then
            Rd_data_out <= ram(to_integer(unsigned(Rd_addr_in)));
            if Wr_en_in = '1' then
                ram(to_integer(unsigned(Wr_addr_in))) <= Wr_data_in;
            end if;
        end if;
    end process;
end architecture;