library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom is
    generic (
        BUS_WIDTH       : integer := 32;
        ROM_DEPTH       : integer := 64;
        ADDRESS_WIDTH   : integer := 6
    );
    port (
        clk         : in std_logic;

        read_en     : in std_logic;
        read_addr   : in std_logic_vector((ADDRESS_WIDTH-1) downto 0);
        read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0)
    );
end rom;

architecture Behavioural of rom is 

    constant MIN_INDEX : integer := 0;
    constant MAX_INDEX : integer := (ROM_DEPTH-1);

    type t_ROM is array (MIN_INDEX to MAX_INDEX) of std_logic_vector((BUS_WIDTH-1) downto 0);

    impure function memory_init (file_name : in string) return t_ROM is
        file init_file      : text open read_mode is file_name;
        variable file_line  : line;
        variable temp_vect  : bit_vector((BUS_WIDTH-1) downto 0);
        variable temp_rom   : t_ROM;
    begin
        -- Read from the file line-by-line
        for i in t_ROM'range loop
            readline(init_file, file_line);
            read(file_line, temp_vect);
            temp_rom(i) := to_stdlogicvector(temp_vect);
        end loop;
        
        return temp_rom;
    end function memory_init;

    signal rom : t_ROM  := memory_init(INITIALISATION_FILE);

begin
    
    READ_PROC: process (clk)
    begin
        if (rising_edge(clk)) then
            if (read_en = '1') then
                read_data   <= rom(conv_integer(read_addr));
            end if;
        end if;
    end process READ_PROC;

end Behavioural;
