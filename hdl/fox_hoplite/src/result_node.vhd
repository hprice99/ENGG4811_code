library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.fox_defs.all;

entity result_node is
    Generic (
        -- Entire network parameters
        NETWORK_ROWS    : integer := 2;
        NETWORK_COLS    : integer := 2;
        NETWORK_NODES   : integer := 4;

        -- Fox's algorithm network paramters
        FOX_NETWORK_STAGES  : integer := 2;
        FOX_NETWORK_NODES   : integer := 4;

        -- Result node parameters
        RESULT_X_COORD  : integer := 0;
        RESULT_Y_COORD  : integer := 2;
    
        -- Node parameters
        X_COORD         : integer := 0;
        Y_COORD         : integer := 0;
        NODE_NUMBER     : integer := 0;

        -- Packet parameters
        COORD_BITS              : integer := 2;
        MULTICAST_GROUP_BITS    : integer := 1;
        MULTICAST_COORD_BITS    : integer := 1;
        MATRIX_TYPE_BITS        : integer := 1;
        MATRIX_COORD_BITS       : integer := 8;
        MATRIX_ELEMENT_BITS     : integer := 32;
        BUS_WIDTH               : integer := 56;

        -- Matrix parameters
        TOTAL_MATRIX_SIZE       : integer := 32;
        FOX_MATRIX_SIZE         : integer := 16;
        
        USE_INITIALISATION_FILE : boolean := True;
        MATRIX_FILE             : string  := "none";
        MATRIX_FILE_LENGTH      : integer := 0;

        ROM_X_COORD             : integer := 0;
        ROM_Y_COORD             : integer := 0;
        
        -- Matrix offset for node
        MATRIX_X_OFFSET : integer := 0;
        MATRIX_Y_OFFSET : integer := 0;

        -- NIC parameters
        PE_TO_NETWORK_FIFO_DEPTH    : integer := 32;
        NETWORK_TO_PE_FIFO_DEPTH    : integer := 32;

        -- UART parameters
        CLK_FREQ           : integer := 50e6;
        ENABLE_UART        : boolean := False;
        UART_FIFO_DEPTH    : integer := 50;
        
        -- PicoRV32 core parameters
        DIVIDE_ENABLED     : std_logic := '0';
        MULTIPLY_ENABLED   : std_logic := '1';
        FIRMWARE           : string    := "firmware.hex";
        MEM_SIZE           : integer   := 4096
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;

        out_char            : out std_logic_vector(7 downto 0);
        out_char_en         : out std_logic;

        uart_tx             : out std_logic;
        
        x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid          : in STD_LOGIC;
        y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid          : in STD_LOGIC;
        
        x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid         : out STD_LOGIC;
        y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid         : out STD_LOGIC;

        out_matrix          : out std_logic_vector(31 downto 0);
        out_matrix_en       : out std_logic;
        out_matrix_end_row  : out std_logic;
        out_matrix_end      : out std_logic;
        
        matrix_multiply_done    : out std_logic
    );
end result_node;

architecture Behavioral of result_node is

    component fox_node
        generic (
            -- Entire network parameters
            NETWORK_ROWS    : integer := 2;
            NETWORK_COLS    : integer := 2;
            NETWORK_NODES   : integer := 4;

            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4;

            -- Result node parameters
            RESULT_X_COORD  : integer := 0;
            RESULT_Y_COORD  : integer := 2;
        
            -- Node parameters
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            NODE_NUMBER     : integer := 0;

            -- Packet parameters
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;

            -- Matrix parameters
            TOTAL_MATRIX_SIZE   : integer := 32;
            FOX_MATRIX_SIZE     : integer := 16;
            
            USE_INITIALISATION_FILE : boolean := True;
            MATRIX_FILE             : string  := "none";
            MATRIX_FILE_LENGTH      : integer := 0;

            ROM_X_COORD             : integer := 0;
            ROM_Y_COORD             : integer := 0;
            
            -- Matrix offset for node
            MATRIX_X_OFFSET : integer := 0;
            MATRIX_Y_OFFSET : integer := 0;

            -- NIC parameters
            PE_TO_NETWORK_FIFO_DEPTH    : integer := 32;
            NETWORK_TO_PE_FIFO_DEPTH    : integer := 32;
            
            -- PicoRV32 core parameters
            DIVIDE_ENABLED     : std_logic := '0';
            MULTIPLY_ENABLED   : std_logic := '1';
            FIRMWARE           : string    := "firmware.hex";
            MEM_SIZE           : integer   := 4096
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;

            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            out_char_ready      : in std_logic;
            
            x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid          : in STD_LOGIC;
            y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid          : in STD_LOGIC;
            
            x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid         : out STD_LOGIC;
            y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid         : out STD_LOGIC;

            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic;
            
            matrix_multiply_done    : out std_logic
        );
    end component fox_node;
    
    component UART_tx_buffered
        Generic (
            CLK_FREQ        : integer := 50e6;
            BAUD_RATE     : integer := 115200;
            PARITY_BIT    : string  := "none";
            USE_DEBOUNCER : boolean := True;

            BUFFER_DEPTH    : integer := 50
        ); 
        Port (
            clk     : in std_logic;
            reset_n : in std_logic;

            data_in         : in std_logic_vector(7 downto 0);
            data_in_valid   : in std_logic;

            uart_tx         : out std_logic;

            buffer_full     : out std_logic
        );
    end component UART_tx_buffered;

    signal reset    : std_logic;
    
    constant BAUD_RATE      : integer := 115200;
    constant PARITY_BIT     : string := "none";
    constant USE_DEBOUNCER  : boolean := True;
    
    constant UART_BUS_WIDTH : integer := 8;
    
    signal pe_to_uart           : std_logic_vector(7 downto 0);
    signal pe_to_uart_valid     : std_logic;
    signal pe_to_uart_ready     : std_logic;
    
    signal buffer_full  : std_logic;

begin

    -- Instantiate node
    out_char    <= pe_to_uart;
    out_char_en <= pe_to_uart_valid;

    FOX_NODE_INITIALISE: fox_node
        generic map (
            -- Entire network parameters
            NETWORK_ROWS    => NETWORK_ROWS,
            NETWORK_COLS    => NETWORK_COLS,
            NETWORK_NODES   => NETWORK_NODES,
    
            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES,
    
            -- Result node parameters
            RESULT_X_COORD  => RESULT_X_COORD,
            RESULT_Y_COORD  => RESULT_Y_COORD,
        
            -- Node parameters
            X_COORD         => X_COORD,
            Y_COORD         => Y_COORD,
            NODE_NUMBER     => NODE_NUMBER,
    
            -- Packet parameters
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS, 
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH,
    
            -- Matrix parameters
            TOTAL_MATRIX_SIZE       => TOTAL_MATRIX_SIZE,
            FOX_MATRIX_SIZE         => FOX_MATRIX_SIZE,
            
            USE_INITIALISATION_FILE => USE_INITIALISATION_FILE,
            MATRIX_FILE             => MATRIX_FILE,
            MATRIX_FILE_LENGTH      => MATRIX_FILE_LENGTH,

            ROM_X_COORD             => ROM_X_COORD,
            ROM_Y_COORD             => ROM_Y_COORD,
            
            -- Matrix offset for node
            MATRIX_X_OFFSET => MATRIX_X_OFFSET,
            MATRIX_Y_OFFSET => MATRIX_X_OFFSET,

            -- NIC parameters
            PE_TO_NETWORK_FIFO_DEPTH      => PE_TO_NETWORK_FIFO_DEPTH,
            NETWORK_TO_PE_FIFO_DEPTH      => NETWORK_TO_PE_FIFO_DEPTH,
            
            -- PicoRV32 core parameters
            DIVIDE_ENABLED     => DIVIDE_ENABLED,
            MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
            FIRMWARE           => FIRMWARE,
            MEM_SIZE           => MEM_SIZE
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
                
            out_char            => pe_to_uart,
            out_char_en         => pe_to_uart_valid,
            out_char_ready      => pe_to_uart_ready,
            
            -- Messages incoming to router
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            
            -- Messages outgoing from router
            x_out               => x_out,
            x_out_valid         => x_out_valid,
            y_out               => y_out,
            y_out_valid         => y_out_valid,
    
            out_matrix          => out_matrix,
            out_matrix_en       => out_matrix_en,
            out_matrix_end_row  => out_matrix_end_row,
            out_matrix_end      => out_matrix_end,
            
            matrix_multiply_done    => matrix_multiply_done
        );
        
    ENABLE_UART_GEN: if (ENABLE_UART = True) generate
        pe_to_uart_ready    <= not buffer_full;

        BUFFERED_UART: uart_tx_buffered
            generic map (
                CLK_FREQ        => CLK_FREQ,
                BAUD_RATE       => BAUD_RATE,
                PARITY_BIT      => PARITY_BIT,
                USE_DEBOUNCER   => USE_DEBOUNCER,
        
                BUFFER_DEPTH    => UART_FIFO_DEPTH
            )
            port map (
                clk     => clk,
                reset_n => reset_n,
        
                data_in         => pe_to_uart,
                data_in_valid   => pe_to_uart_valid,
        
                uart_tx         => uart_tx,
        
                buffer_full     => buffer_full
            );
    end generate ENABLE_UART_GEN;

    DISABLE_UART_GEN: if (ENABLE_UART = false) generate
        pe_to_uart_ready    <= '1';
    end generate DISABLE_UART_GEN;

end Behavioral;
