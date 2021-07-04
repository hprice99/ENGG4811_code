library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nic_dual is
    generic (
        BUS_WIDTH   : integer := 32;
        FIFO_DEPTH  : integer := 64
    );
    port (
        clk                 : in std_logic;
        reset_n             : in std_logic;

        -- Messages from PE to network
        from_pe_valid       : in std_logic;
        from_pe_data        : in std_logic_vector((BUS_WIDTH-1) downto 0);

        network_ready       : in std_logic;
        to_network_valid    : out std_logic;
        to_network_data     : out std_logic_vector((BUS_WIDTH-1) downto 0);
        
        pe_to_network_full  : out std_logic;
        pe_to_network_empty : out std_logic;

        -- Messages from network to PE
        from_network_valid  : in std_logic;
        from_network_data   : in std_logic_vector((BUS_WIDTH-1) downto 0);

        pe_ready            : in std_logic;
        to_pe_valid         : out std_logic;
        to_pe_data          : out std_logic_vector((BUS_WIDTH-1) downto 0);

        -- TODO May need to trigger the router so that the packet can be deflected if it cannot be stored in the FIFO
        network_to_pe_full  : out std_logic;
        network_to_pe_empty : out std_logic
    );
end nic_dual;

architecture Behavioural of nic_dual is

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

    signal pe_to_network_fifo_write_en, pe_to_network_fifo_read_en      : std_logic;
    signal pe_to_network_fifo_full, pe_to_network_fifo_empty            : std_logic;
    signal pe_to_network_fifo_write_data, pe_to_network_fifo_read_data  : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal network_to_pe_fifo_write_en, network_to_pe_fifo_read_en      : std_logic;
    signal network_to_pe_fifo_full, network_to_pe_fifo_empty            : std_logic;
    signal network_to_pe_fifo_write_data, network_to_pe_fifo_read_data  : std_logic_vector((BUS_WIDTH-1) downto 0);

begin

    ----------------------------------------------------------------
    -- PE to network FIFO
    PE_TO_NETWORK_FIFO: fifo_sync
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (
        clk         => clk,
        reset_n     => reset_n,
        
        write_en    => pe_to_network_fifo_write_en,
        write_data  => pe_to_network_fifo_write_data,
        
        read_en     => pe_to_network_fifo_read_en,
        read_data   => pe_to_network_fifo_read_data,
        
        full        => pe_to_network_fifo_full,
        empty       => pe_to_network_fifo_empty
    );

    -- Writing to PE to network FIFO
    PE_TO_NETWORK_FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                pe_to_network_fifo_write_data <= (others => '0');
                pe_to_network_fifo_write_en   <= '0';
            elsif (pe_to_network_fifo_full = '0') then
                if (from_pe_valid = '1') then
                    pe_to_network_fifo_write_data     <= from_pe_data;
                    pe_to_network_fifo_write_en       <= '1';
                else
                    pe_to_network_fifo_write_en       <= '0';
                end if;
            end if;
        end if;
    end process PE_TO_NETWORK_FIFO_WRITE;

    -- Read from PE to network FIFO
    PE_TO_NETWORK_FIFO_READ_ENABLE: process (pe_to_network_fifo_empty, network_ready)
    begin
        if (pe_to_network_fifo_empty = '0') then
            pe_to_network_fifo_read_en   <= network_ready;
        else
            pe_to_network_fifo_read_en   <= '0';
        end if;
    end process PE_TO_NETWORK_FIFO_READ_ENABLE;

    to_network_valid   <= pe_to_network_fifo_read_en;
    to_network_data    <= pe_to_network_fifo_read_data;
    
    pe_to_network_full    <= pe_to_network_fifo_full;
    pe_to_network_empty   <= pe_to_network_fifo_empty;
    ----------------------------------------------------------------
    
    ----------------------------------------------------------------
    -- Network to PE FIFO
    NETWORK_TO_PE_FIFO: fifo_sync
    generic map (
        BUS_WIDTH   => BUS_WIDTH,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (
        clk         => clk,
        reset_n     => reset_n,
        
        write_en    => network_to_pe_fifo_write_en,
        write_data  => network_to_pe_fifo_write_data,
        
        read_en     => network_to_pe_fifo_read_en,
        read_data   => network_to_pe_fifo_read_data,
        
        full        => network_to_pe_fifo_full,
        empty       => network_to_pe_fifo_empty
    );

    -- Writing to PE to network FIFO
    NETWORK_TO_PE_FIFO_WRITE: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                network_to_pe_fifo_write_data <= (others => '0');
                network_to_pe_fifo_write_en   <= '0';
            elsif (network_to_pe_fifo_full = '0') then
                if (from_network_valid = '1') then
                    network_to_pe_fifo_write_data     <= from_network_data;
                    network_to_pe_fifo_write_en       <= '1';
                else
                    network_to_pe_fifo_write_en       <= '0';
                end if;
            end if;
        end if;
    end process NETWORK_TO_PE_FIFO_WRITE;

    -- Read from PE to network FIFO
    NETWORK_TO_PE_FIFO_READ_ENABLE: process (network_to_pe_fifo_empty, pe_ready)
    begin
        if (network_to_pe_fifo_empty = '0') then
            network_to_pe_fifo_read_en   <= pe_ready;
        else
            network_to_pe_fifo_read_en   <= '0';
        end if;
    end process NETWORK_TO_PE_FIFO_READ_ENABLE;

    to_pe_valid   <= network_to_pe_fifo_read_en;
    to_pe_data    <= network_to_pe_fifo_read_data;
    
    network_to_pe_full    <= network_to_pe_fifo_full;
    network_to_pe_empty   <= network_to_pe_fifo_empty;

end Behavioural;
