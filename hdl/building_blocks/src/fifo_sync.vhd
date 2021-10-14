library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_sync is
    generic (
        BUS_WIDTH   : integer := 32;
        FIFO_DEPTH  : integer := 64
    );
    port (
        clk         : in std_logic;
        reset_n     : in std_logic;

        write_en    : in std_logic;
        write_data  : in std_logic_vector((BUS_WIDTH-1) downto 0);
        
        read_en     : in std_logic;
        read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0);
        
        full        : out std_logic;
        empty       : out std_logic
    );
end fifo_sync;

architecture Behavioural of fifo_sync is 

    constant MIN_INDEX : integer := 0;
    constant MAX_INDEX : integer := (FIFO_DEPTH-1);

    type t_FIFO is array (MIN_INDEX to MAX_INDEX) of std_logic_vector((BUS_WIDTH-1) downto 0);
    signal fifo : t_FIFO;
    
    signal write_index, read_index : integer range MIN_INDEX to MAX_INDEX;

    signal entries : integer;

    signal full_flag, empty_flag : std_logic;

begin
    
    PROC_ENTRY_COUNT: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                entries <= 0;
            else
                -- Increment entry count if there is a write and no read
                if (write_en = '1' and read_en = '0') then
                    entries <= entries + 1;
                -- Decrement entry count if there is a read and no write
                elsif (write_en = '0' and read_en = '1') then
                    entries <= entries - 1;
                -- If there is no read and no write, or simultaneous read and write, then entry count does not change
                else
                    entries <= entries;
                end if;
            end if;
        end if;
    end process PROC_ENTRY_COUNT;

    PROC_WRITE_INDEX: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                write_index <= 0;
            else
                -- Only write if the FIFO is not full
                if (write_en = '1' and full_flag = '0') then
                    -- Reset to start if the end of the FIFO is reached
                    if (write_index = MAX_INDEX) then
                        write_index <= MIN_INDEX;
                    else
                        write_index <= write_index + 1;
                    end if;
                end if;
            end if;
        end if;
    end process PROC_WRITE_INDEX;

    PROC_READ_INDEX: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                read_index <= 0;
            else
                -- Only read if the FIFO is not empty
                if (read_en = '1' and empty_flag = '0') then
                    -- Reset to start if the end of the FIFO is reached
                    if (read_index = MAX_INDEX) then
                        read_index <= MIN_INDEX;
                    else
                        read_index <= read_index + 1;
                    end if;
                end if;
            end if;
        end if;
    end process PROC_READ_INDEX;

    PROC_WRITE_DATA: process (clk)
    begin
        if (rising_edge(clk)) then
            if (write_en = '1') then
                fifo(write_index) <= write_data;
            end if;
        end if;
    end process PROC_WRITE_DATA;

    -- Set read data (no latency)
    read_data <= fifo(read_index);

    -- Full and empty flags
    full_flag   <= '1' when entries = FIFO_DEPTH    else '0';
    empty_flag  <= '1' when entries = 0             else '0';

    full    <= full_flag;
    empty   <= empty_flag;
    
    -- synthesis translate_off
    FLAG_ASSERTIONS: process (clk)
    begin
        if rising_edge(clk) then
            if (write_en = '1' and full_flag = '1') then
                report "FAILURE - Trying to write to a full FIFO" severity failure;
            end if;
    
            if (read_en = '1' and empty_flag = '1') then
                report "FAILURE - Trying to read from an empty FIFO" severity failure;
            end if;
        end if;
    end process FLAG_ASSERTIONS;
    -- synthesis translate_on

end Behavioural;

