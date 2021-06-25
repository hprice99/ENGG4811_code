library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nic_testbench is
    generic (
        BUS_WIDTH   : integer := 32;
        FIFO_DEPTH  : integer := 64
    );
    port (
        clk                 : in std_logic;
        reset_n             : in std_logic;

        pe_in_valid         : in std_logic;
        pe_in_data          : in std_logic_vector((BUS_WIDTH-1) downto 0);

        network_ready       : in std_logic;

        network_out_valid   : out std_logic;
        network_out_data    : out std_logic_vector((BUS_WIDTH-1) downto 0);
        
        full           : out std_logic;
        empty          : out std_logic
    );
end nic_testbench;

architecture Behavioural of nic_testbench is

    component fifo_sync
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
    end component fifo_sync;

    signal fifo_write_en, fifo_read_en      : std_logic;
    signal fifo_full, fifo_empty            : std_logic;
    signal fifo_write_data, fifo_read_data  : std_logic_vector((BUS_WIDTH-1) downto 0);

begin

    FIFO: fifo_sync
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (
        clk         => clk,
        reset_n     => reset_n,
        
        write_en    => fifo_write_en,
        write_data  => fifo_write_data,
        
        read_en     => fifo_read_en,
        read_data   => fifo_read_data,
        
        full        => fifo_full,
        empty       => fifo_empty
    );

    -- Writing to FIFO
    FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                fifo_write_data <= (others => '0');
                fifo_write_en   <= '0';
            elsif (fifo_full = '0') then
                if (pe_in_valid = '1') then
                    fifo_write_data     <= pe_in_data;
                    fifo_write_en       <= '1';
                else
                    fifo_write_en       <= '0';
                end if;
            end if;
        end if;
    end process FIFO_WRITE;

    -- Read from FIFO
    FIFO_READ_ENABLE: process (fifo_empty, network_ready)
    begin
        if (fifo_empty = '0') then
            fifo_read_en   <= network_ready;
        else
            fifo_read_en   <= '0';
        end if;
    end process FIFO_READ_ENABLE;

    network_out_valid   <= fifo_read_en;
    network_out_data    <= fifo_read_data;
    
    full    <= fifo_full;
    empty   <= fifo_empty;

end Behavioural;
