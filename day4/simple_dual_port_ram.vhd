library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_dual_port_ram is
    generic (
        DATA_WIDTH : integer;
        ADDR_WIDTH : integer;
        INIT_BIT   : std_logic := '0'  -- set to 1 to preload with all 1's
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
    signal ram : ram_arr_t := (others => (others => INIT_BIT));
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