library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_sync_wrapper is
    generic (
        BUS_WIDTH   : integer := 32;
        FIFO_DEPTH  : integer := 64;
        
        USE_INITIALISATION_FILE : boolean := True;
        INITIALISATION_FILE     : string := "none";
        INITIALISATION_LENGTH   : integer := 0
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
end fifo_sync_wrapper;

architecture Behavioral of fifo_sync_wrapper is

    component fifo_sync_memory_initialise
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64;
            
            INITIALISATION_FILE     : string := "none";
            INITIALISATION_LENGTH   : integer := 0
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
    end component fifo_sync_memory_initialise;
    
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

begin

    UNINITIALISED_FIFO_GEN: if (INITIALISATION_FILE = "none" or USE_INITIALISATION_FILE = False) generate
        UNINITIALISED_FIFO: fifo_sync
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                FIFO_DEPTH  => FIFO_DEPTH
            )
            port map (
                clk         => clk,
                reset_n     => reset_n,
                
                write_en    => write_en,
                write_data  => write_data,
                
                read_en     => read_en,
                read_data   => read_data,
                
                full        => full,
                empty       => empty
            );
    end generate UNINITIALISED_FIFO_GEN;

    INITIALISED_FIFO_GEN: if (INITIALISATION_FILE /= "none" and USE_INITIALISATION_FILE = True) generate
        INITIALISED_FIFO: fifo_sync_memory_initialise
            generic map (
                BUS_WIDTH   => BUS_WIDTH,
                FIFO_DEPTH  => FIFO_DEPTH,
                
                INITIALISATION_FILE     => INITIALISATION_FILE,
                INITIALISATION_LENGTH   => INITIALISATION_LENGTH
            )
            port map (
                clk         => clk,
                reset_n     => reset_n,
                
                write_en    => write_en,
                write_data  => write_data,
                
                read_en     => read_en,
                read_data   => read_data,
                
                full        => full,
                empty       => empty
            );
    end generate INITIALISED_FIFO_GEN;

end Behavioral;
