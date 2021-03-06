library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;
use xil_defaultlib.matrix_config.all;
use xil_defaultlib.firmware_config.all;

entity top is
    Generic (
        -- Fox's algorithm network paramters
        FOX_NETWORK_STAGES  : integer := 2;
        FOX_NETWORK_NODES   : integer := 4;
        
        FOX_FIRMWARE            : string := "firmware_hoplite.hex";
        FOX_FIRMWARE_MEM_SIZE   : integer := 4096; 
        
        RESULT_FIRMWARE             : string := "firmware_hoplite_result.hex";
        RESULT_FIRMWARE_MEM_SIZE    : integer := 8192;

        CLK_FREQ            : integer := 50e6;
        ENABLE_UART         : boolean := False
    );
    Port ( 
           reset_n              : in std_logic;
           clk                  : in std_logic;
           
           LED                  : out std_logic_vector((FOX_NETWORK_NODES-1) downto 0);
           
           out_char             : out t_Char;
           out_char_en          : out t_MessageValid;
           
           uart_tx              : out std_logic;
           
           out_matrix           : out t_MatrixOut;
           out_matrix_en        : out t_MessageValid;
           out_matrix_end_row   : out t_MessageValid;
           out_matrix_end       : out t_MessageValid
    );
end top;

architecture Behavioral of top is

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

            LED                 : out std_logic;

            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;
            out_char_ready      : in std_logic;
            
            x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            x_in_valid          : in std_logic;
            y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            y_in_valid          : in std_logic;
            
            x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            x_out_valid         : out std_logic;
            y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            y_out_valid         : out std_logic;

            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic
        );
    end component fox_node;

    component result_node
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
    
            LED                 : out std_logic;
    
            out_char            : out std_logic_vector(7 downto 0);
            out_char_en         : out std_logic;

            uart_tx             : out std_logic;
            
            x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            x_in_valid          : in std_logic;
            y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            y_in_valid          : in std_logic;
            
            x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            x_out_valid         : out std_logic;
            y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            y_out_valid         : out std_logic;
    
            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic
        );
    end component result_node;

    component rom_node
        Generic (   
            -- Node parameters
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
    
            -- Packet parameters
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;
    
            FIFO_DEPTH              : integer := 64;
            
            USE_INITIALISATION_FILE : boolean := True;
            MATRIX_FILE             : string  := "none";
            ROM_DEPTH               : integer := 64;
            ROM_ADDRESS_WIDTH       : integer := 6;

            USE_BURST               : boolean := False;
            BURST_LENGTH            : integer := 0
        );
        Port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            rom_read_complete   : out std_logic;
    
            x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            x_in_valid          : in std_logic;
            y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
            y_in_valid          : in std_logic;
            
            x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            x_out_valid         : out std_logic;
            y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
            y_out_valid         : out std_logic
        );
    end component rom_node;

    component hoplite_router_unicast
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk             : in std_logic;
            reset_n         : in std_logic;
            
            x_in            : in std_logic_vector((BUS_WIDTH-1) downto 0);
            x_in_valid      : in std_logic;
            y_in            : in std_logic_vector((BUS_WIDTH-1) downto 0);
            y_in_valid      : in std_logic;
            pe_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in std_logic;
            
            x_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
            x_out_valid     : out std_logic;
            y_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
            y_out_valid     : out std_logic;
            pe_out          : out std_logic_vector((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out std_logic;
            pe_backpressure : out std_logic
        );
    end component hoplite_router_unicast;
    
    -- Array of message interfaces between nodes
    signal x_messages_out, y_messages_out : t_Message;
    signal x_messages_out_valid, y_messages_out_valid : t_MessageValid;
    signal x_messages_in, y_messages_in : t_Message;
    signal x_messages_in_valid, y_messages_in_valid : t_MessageValid;

    constant FOX_DIVIDE_ENABLED     : std_logic := '0';
    constant RESULT_DIVIDE_ENABLED  : std_logic := '1';
    constant MULTIPLY_ENABLED       : std_logic := '1';

    constant combined_matrix_file   : string := "combined.mif";
    constant matrix_file_length     : integer := 2 * TOTAL_MATRIX_ELEMENTS;
    constant ROM_ADDRESS_WIDTH      : integer := ceil_log2(matrix_file_length);
    
    constant USE_BURST              : boolean := True;
    constant BURST_LENGTH           : integer := matrix_file_length / 2;

begin

    -- Generate the network
    NETWORK_ROW_GEN: for i in 0 to (NETWORK_ROWS-1) generate
        NETWORK_COL_GEN: for j in 0 to (NETWORK_COLS-1) generate
            constant prev_y         : integer := ((i-1) mod NETWORK_ROWS);
            constant prev_x         : integer := ((j-1) mod NETWORK_COLS);
            constant curr_y         : integer := i;
            constant curr_x         : integer := j;
            constant next_y         : integer := ((i+1) mod NETWORK_ROWS);
            constant next_x         : integer := ((j+1) mod NETWORK_COLS);
        begin
            -- Connect in and out messages
            x_messages_in(curr_x, curr_y)       <= x_messages_out(prev_x, curr_y);
            x_messages_in_valid(curr_x, curr_y) <= x_messages_out_valid(prev_x, curr_y);

            y_messages_in(curr_x, curr_y)       <= y_messages_out(curr_x, next_y);
            y_messages_in_valid(curr_x, curr_y) <= y_messages_out_valid(curr_x, next_y);
        
            FOX_NETWORK_GEN: if (curr_x < FOX_NETWORK_STAGES and curr_y < FOX_NETWORK_STAGES) generate
                constant node_number    : integer := i * FOX_NETWORK_STAGES + j;
                constant y_offset       : integer := i * (FOX_MATRIX_SIZE);
                constant x_offset       : integer := j * (FOX_MATRIX_SIZE);
                constant matrix_file    : string  := MATRIX_INIT_FILE_PREFIX & integer'image(node_number) & MATRIX_INIT_FILE_SUFFIX;
            begin
                -- Instantiate result node
                RESULT_GEN: if (curr_x = RESULT_X_COORD and curr_y = RESULT_Y_COORD) generate
                    RESULT_NODE_INITIALISE: result_node
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
                        X_COORD         => curr_x,
                        Y_COORD         => curr_y,
                        NODE_NUMBER     => node_number,

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
                        
                        USE_INITIALISATION_FILE => USE_MATRIX_INIT_FILE,
                        MATRIX_FILE             => matrix_file,
                        MATRIX_FILE_LENGTH      => MATRIX_INIT_FILE_LENGTH,

                        ROM_X_COORD             => ROM_X_COORD,
                        ROM_Y_COORD             => ROM_Y_COORD,
                        
                        -- Matrix offset for node
                        MATRIX_X_OFFSET => x_offset,
                        MATRIX_Y_OFFSET => y_offset,

                        -- NIC parameters
                        PE_TO_NETWORK_FIFO_DEPTH    => RESULT_PE_TO_NETWORK_FIFO_DEPTH,
                        NETWORK_TO_PE_FIFO_DEPTH    => RESULT_NETWORK_TO_PE_FIFO_DEPTH,
    
                        -- UART parameters
                        CLK_FREQ        => CLK_FREQ,
                        ENABLE_UART     => ENABLE_UART,
                        UART_FIFO_DEPTH => RESULT_UART_FIFO_DEPTH,
                        
                        -- PicoRV32 core parameters
                        DIVIDE_ENABLED     => RESULT_DIVIDE_ENABLED,
                        MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
                        FIRMWARE           => RESULT_FIRMWARE,
                        MEM_SIZE           => RESULT_FIRMWARE_MEM_SIZE
                    )
                    port map (
                        clk                 => clk,
                        reset_n             => reset_n,
                        
                        LED                 => LED(node_number),

                        out_char            => out_char(curr_x, curr_y),
                        out_char_en         => out_char_en(curr_x, curr_y),
                        
                        uart_tx             => uart_tx,
                        
                        -- Messages incoming to router
                        x_in                => x_messages_in(curr_x, curr_y),
                        x_in_valid          => x_messages_in_valid(curr_x, curr_y),                  
                        y_in                => y_messages_in(curr_x, curr_y),
                        y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                        
                        -- Messages outgoing from router
                        x_out               => x_messages_out(curr_x, curr_y),
                        x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                        y_out               => y_messages_out(curr_x, curr_y),
                        y_out_valid         => y_messages_out_valid(curr_x, curr_y),

                        out_matrix          => out_matrix(curr_x, curr_y),
                        out_matrix_en       => out_matrix_en(curr_x, curr_y),
                        out_matrix_end_row  => out_matrix_end_row(curr_x, curr_y),
                        out_matrix_end      => out_matrix_end(curr_x, curr_y)
                    );
                end generate RESULT_GEN;
                
                FOX_GEN: if (curr_x /= RESULT_X_COORD or curr_y /= RESULT_Y_COORD) generate
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
                        X_COORD         => curr_x,
                        Y_COORD         => curr_y,
                        NODE_NUMBER     => node_number,

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
                        
                        USE_INITIALISATION_FILE => USE_MATRIX_INIT_FILE,
                        MATRIX_FILE             => matrix_file,
                        MATRIX_FILE_LENGTH      => MATRIX_INIT_FILE_LENGTH,

                        ROM_X_COORD             => ROM_X_COORD,
                        ROM_Y_COORD             => ROM_Y_COORD,
                        
                        -- Matrix offset for node
                        MATRIX_X_OFFSET => x_offset,
                        MATRIX_Y_OFFSET => y_offset,

                        -- NIC parameters
                        PE_TO_NETWORK_FIFO_DEPTH    => FOX_PE_TO_NETWORK_FIFO_DEPTH,
                        NETWORK_TO_PE_FIFO_DEPTH    => FOX_NETWORK_TO_PE_FIFO_DEPTH,
                        
                        -- PicoRV32 core parameters
                        DIVIDE_ENABLED     => FOX_DIVIDE_ENABLED,
                        MULTIPLY_ENABLED   => MULTIPLY_ENABLED,
                        FIRMWARE           => FOX_FIRMWARE,
                        MEM_SIZE           => FOX_FIRMWARE_MEM_SIZE
                    )
                    port map (
                        clk                 => clk,
                        reset_n             => reset_n,
                        
                        LED                 => LED(node_number),

                        out_char            => out_char(curr_x, curr_y),
                        out_char_en         => out_char_en(curr_x, curr_y),
                        out_char_ready      => '1',
                        
                        -- Messages incoming to router
                        x_in                => x_messages_in(curr_x, curr_y),
                        x_in_valid          => x_messages_in_valid(curr_x, curr_y),
                        y_in                => y_messages_in(curr_x, curr_y),
                        y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                        
                        -- Messages outgoing from router
                        x_out               => x_messages_out(curr_x, curr_y),
                        x_out_valid         => x_messages_out_valid(curr_x, curr_y),
                        y_out               => y_messages_out(curr_x, curr_y),
                        y_out_valid         => y_messages_out_valid(curr_x, curr_y),

                        out_matrix          => out_matrix(curr_x, curr_y),
                        out_matrix_en       => out_matrix_en(curr_x, curr_y),
                        out_matrix_end_row  => out_matrix_end_row(curr_x, curr_y),
                        out_matrix_end      => out_matrix_end(curr_x, curr_y)
                    );
                end generate FOX_GEN;
            end generate FOX_NETWORK_GEN;

            PERIPHERAL_NODE_GEN: if (curr_x >= FOX_NETWORK_STAGES or curr_y >= FOX_NETWORK_STAGES) generate
                ROM_GEN: if (curr_x = ROM_X_COORD and curr_y = ROM_Y_COORD) generate
                    ROM: rom_node
                    generic map (
                        -- Node parameters
                        X_COORD => curr_x,
                        Y_COORD => curr_y,

                        -- Packet parameters
                        COORD_BITS              => COORD_BITS,
                        MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
                        MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
                        MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
                        MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
                        MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
                        BUS_WIDTH               => BUS_WIDTH,
                
                        FIFO_DEPTH              => 8,
                        
                        USE_INITIALISATION_FILE => True,
                        MATRIX_FILE             => combined_matrix_file,
                        ROM_DEPTH               => matrix_file_length,
                        ROM_ADDRESS_WIDTH       => ROM_ADDRESS_WIDTH,

                        USE_BURST               => USE_BURST,
                        BURST_LENGTH            => BURST_LENGTH
                    )
                    port map (
                        clk                 => clk,
                        reset_n             => reset_n,
                        
                        rom_read_complete   => open,
                
                        x_in                    => x_messages_in(curr_x, curr_y),
                        x_in_valid              => x_messages_in_valid(curr_x, curr_y),
                        y_in                    => y_messages_in(curr_x, curr_y),
                        y_in_valid              => y_messages_in_valid(curr_x, curr_y),
                        
                        x_out                   => x_messages_out(curr_x, curr_y),
                        x_out_valid             => x_messages_out_valid(curr_x, curr_y),
                        y_out                   => y_messages_out(curr_x, curr_y),
                        y_out_valid             => y_messages_out_valid(curr_x, curr_y)
                    );
                end generate ROM_GEN;
                
                ROUTER_GEN: if (curr_x /= ROM_X_COORD or curr_y /= ROM_Y_COORD) generate
                    ROUTER: hoplite_router_unicast
                        generic map (
                            BUS_WIDTH   => BUS_WIDTH,
                            X_COORD     => curr_x,
                            Y_COORD     => curr_y,
                            COORD_BITS  => COORD_BITS
                        )
                        port map (
                            clk                 => clk,
                            reset_n             => reset_n,
                            
                            x_in                => x_messages_in(curr_x, curr_y),
                            x_in_valid          => x_messages_in_valid(curr_x, curr_y),
                            y_in                => y_messages_in(curr_x, curr_y),
                            y_in_valid          => y_messages_in_valid(curr_x, curr_y),
                            pe_in               => (others => '0'),
                            pe_in_valid         => '0',
                            pe_backpressure     => open,
                            
                            x_out                   => x_messages_out(curr_x, curr_y),
                            x_out_valid             => x_messages_out_valid(curr_x, curr_y),
                            y_out                   => y_messages_out(curr_x, curr_y),
                            y_out_valid             => y_messages_out_valid(curr_x, curr_y),
                            pe_out              => open,
                            pe_out_valid        => open
                        );
                end generate ROUTER_GEN;
            end generate PERIPHERAL_NODE_GEN;
        end generate NETWORK_COL_GEN;
    end generate NETWORK_ROW_GEN;

    
end Behavioral;
