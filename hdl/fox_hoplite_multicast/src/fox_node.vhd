library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

entity fox_node is
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
        
        -- Multicast parameters
        USE_MULTICAST           : boolean := False;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1;

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
        out_char_ready      : in std_logic;
        
        x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        x_in_valid          : in std_logic;
        y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        y_in_valid          : in std_logic;
        multicast_in        : in std_logic_vector((BUS_WIDTH-1) downto 0);
        multicast_in_valid  : in std_logic;
        
        x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        x_out_valid         : out std_logic;
        y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        y_out_valid         : out std_logic;
        multicast_out       : out std_logic_vector((BUS_WIDTH-1) downto 0);
        multicast_out_valid : out std_logic;
        multicast_backpressure  : in std_logic;

        out_matrix          : out std_logic_vector(31 downto 0);
        out_matrix_en       : out std_logic;
        out_matrix_end_row  : out std_logic;
        out_matrix_end      : out std_logic
    );
end fox_node;

architecture Behavioral of fox_node is

    component hoplite_router_multicast is
        Generic (
            BUS_WIDTH               : integer := 32;
            X_COORD                 : integer := 0;
            Y_COORD                 : integer := 0;
            COORD_BITS              : integer := 1;
            
            MULTICAST_COORD_BITS    : integer := 1;
            MULTICAST_X_COORD       : integer := 1;
            MULTICAST_Y_COORD       : integer := 1;
            USE_MULTICAST           : boolean := False
        );
        Port ( 
            clk             : in std_logic;
            reset_n         : in std_logic;
            
            -- Input (messages received by router)
            x_in            : in std_logic_vector((BUS_WIDTH-1) downto 0);
            x_in_valid      : in std_logic;
            
            y_in            : in std_logic_vector((BUS_WIDTH-1) downto 0);
            y_in_valid      : in std_logic;
            
            pe_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in std_logic;
            pe_backpressure : out std_logic;
            
            multicast_in            : in std_logic_vector((BUS_WIDTH-1) downto 0);
            multicast_in_valid      : in std_logic;

            -- Output (messages sent out of router)
            x_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
            x_out_valid     : out std_logic;
            
            y_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
            y_out_valid     : out std_logic;
            
            pe_out          : out std_logic_vector((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out std_logic;
            
            multicast_out           : out std_logic_vector((BUS_WIDTH-1) downto 0);
            multicast_out_valid     : out std_logic;
            multicast_backpressure  : in std_logic
        );
    end component hoplite_router_multicast;
    
    component nic_dual
        generic (
            BUS_WIDTH   : integer := 32;
            
            PE_TO_NETWORK_FIFO_DEPTH    : integer := 32;
            NETWORK_TO_PE_FIFO_DEPTH    : integer := 32;
            
            USE_INITIALISATION_FILE : boolean := True;
            INITIALISATION_FILE     : string := "none";
            INITIALISATION_LENGTH   : integer := 0
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
    
            network_to_pe_full  : out std_logic;
            network_to_pe_empty : out std_logic
        );
    end component nic_dual;
   
    component message_encoder
        generic (
            COORD_BITS              : integer := 2;
            
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MULTICAST_X_COORD       : integer := 1;
            MULTICAST_Y_COORD       : integer := 1;
            
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56
        );
        port (
            clk                         : in std_logic;
            reset_n                     : in std_logic;
            
            x_coord_in                  : in std_logic_vector((COORD_BITS-1) downto 0);
            x_coord_in_valid            : in std_logic;
            
            y_coord_in                  : in std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_in_valid            : in std_logic;

            multicast_group_in          : in std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            multicast_group_in_valid    : in std_logic;

            ready_flag_in                : in std_logic;
            ready_flag_in_valid          : in std_logic;

            result_flag_in              : in std_logic;
            result_flag_in_valid        : in std_logic;

            matrix_type_in              : in std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_type_in_valid        : in std_logic;

            matrix_x_coord_in           : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_x_coord_in_valid     : in std_logic;

            matrix_y_coord_in           : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_in_valid     : in std_logic;
            
            matrix_element_in           : in std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            matrix_element_in_valid     : in std_logic;
            
            packet_complete_in          : in std_logic;
            
            packet_out                  : out std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_out_valid            : out std_logic
        );
    end component message_encoder;

    component message_decoder
        generic (
            COORD_BITS              : integer := 2;
            
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MULTICAST_X_COORD       : integer := 1;
            MULTICAST_Y_COORD       : integer := 1;
            
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            packet_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_in_valid     : in std_logic;
            
            x_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            multicast_group_out : out std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            ready_flag_out       : out std_logic;
            result_flag_out     : out std_logic;
            matrix_type_out     : out std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_out  : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_out  : out std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

            packet_out_valid    : out std_logic;
            
            packet_read         : in std_logic
        );
    end component message_decoder;
    
    component system
        generic (
            -- Entire network parameters
            NETWORK_ROWS    : integer := 2;
            NETWORK_COLS    : integer := 2;
            NETWORK_NODES   : integer := 4;

            -- Fox's algorithm network paramters
            FOX_NETWORK_STAGES  : integer := 2;
            FOX_NETWORK_NODES   : integer := 4;

            RESULT_X_COORD  : integer := 0;
            RESULT_Y_COORD  : integer := 2;
        
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            NODE_NUMBER     : integer := 0;

            FOX_MATRIX_SIZE : integer := 16;
            
            USE_MATRIX_INIT_FILE    : boolean  := True;
            ROM_X_COORD             : integer := 0;
            ROM_Y_COORD             : integer := 0;
            
            -- Matrix offset for node
            MATRIX_X_OFFSET : integer := 0;
            MATRIX_Y_OFFSET : integer := 0;

            -- Network packet format
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            
            DIVIDE_ENABLED     : std_logic := '0';
            MULTIPLY_ENABLED   : std_logic := '1';
            FIRMWARE           : string    := "firmware.hex";
            MEM_SIZE           : integer   := 4096
        );
        port (
            clk                     : in std_logic;
            reset_n                 : in std_logic;
            
            LED                     : out std_logic;
            
            out_char                : out std_logic_vector(7 downto 0);
            out_char_en             : out std_logic;
            out_char_ready          : in std_logic;
            
            x_coord_out                 : out std_logic_vector((COORD_BITS-1) downto 0);
            x_coord_out_valid           : out std_logic;
            
            y_coord_out                 : out std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_out_valid           : out std_logic;

            multicast_group_out         : out std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            multicast_group_out_valid   : out std_logic;

            ready_flag_out               : out std_logic;
            ready_flag_out_valid         : out std_logic;

            result_flag_out             : out std_logic;
            result_flag_out_valid       : out std_logic;

            matrix_type_out             : out std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_type_out_valid       : out std_logic;

            matrix_x_coord_out          : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_x_coord_out_valid    : out std_logic;

            matrix_y_coord_out          : out std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_out_valid    : out std_logic;
            
            matrix_element_out          : out std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            matrix_element_out_valid    : out std_logic;
            
            packet_complete_out     : out std_logic;
            
            message_out_ready       : in std_logic;
            
            multicast_group_in      : in std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
            ready_flag_in            : in std_logic;
            result_flag_in          : in std_logic;
            matrix_type_in          : in std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
            matrix_x_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_y_coord_in       : in std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
            matrix_element_in       : in std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
            message_in_valid        : in std_logic; 
            message_in_available    : in std_logic;
            message_in_read         : out std_logic;

            out_matrix          : out std_logic_vector(31 downto 0);
            out_matrix_en       : out std_logic;
            out_matrix_end_row  : out std_logic;
            out_matrix_end      : out std_logic;
            
            trap                    : out std_logic
        );
    end component system;
    
    -- Messages from PE to network
    signal pe_message_out       : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : std_logic;
    
    signal pe_to_network_message    : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_to_network_valid      : std_logic;
    
    signal pe_backpressure          : std_logic;   
    signal router_ready             : std_logic;
    
    signal pe_to_network_full, pe_to_network_empty   : std_logic;
    
    -- Messages from network to PE
    signal pe_message_in        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_message_in_valid  : std_logic;
    
    signal network_to_pe_message    : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal network_to_pe_valid      : std_logic;
    
    signal pe_ready : std_logic;
    
    signal network_to_pe_full, network_to_pe_empty  : std_logic;
    
    -- Packets routed out
    signal x_out_d, y_out_d             : std_logic_vector ((BUS_WIDTH-1) downto 0);
    signal x_out_valid_d, y_out_valid_d : std_logic;
    
    -- Message encoder signals
    signal processor_out_message_x_coord, processor_out_message_y_coord             : std_logic_vector((COORD_BITS-1) downto 0);
    signal processor_out_message_x_coord_valid, processor_out_message_y_coord_valid : std_logic;
    
    signal processor_out_multicast_group  : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal processor_out_multicast_group_valid : std_logic;

    signal processor_out_ready_flag, processor_out_result_flag   : std_logic;
    signal processor_out_ready_flag_valid, processor_out_result_flag_valid : std_logic;

    signal processor_out_matrix_type        : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal processor_out_matrix_type_valid  : std_logic;

    signal processor_out_matrix_x_coord, processor_out_matrix_y_coord   : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal processor_out_matrix_x_coord_valid, processor_out_matrix_y_coord_valid   : std_logic;

    signal processor_out_matrix_element   : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);
    signal processor_out_matrix_element_valid   : std_logic;
    
    signal processor_out_packet_complete    : std_logic;
    
    -- Message decoder signals
    signal processor_in_multicast_group : std_logic_vector((MULTICAST_GROUP_BITS-1) downto 0);
    signal processor_in_ready_flag       : std_logic;
    signal processor_in_result_flag     : std_logic;
    signal processor_in_matrix_type     : std_logic_vector((MATRIX_TYPE_BITS-1) downto 0);
    signal processor_in_matrix_x_coord  : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal processor_in_matrix_y_coord  : std_logic_vector((MATRIX_COORD_BITS-1) downto 0);
    signal processor_in_matrix_element  : std_logic_vector((MATRIX_ELEMENT_BITS-1) downto 0);

    signal processor_in_message_valid   : std_logic;
    signal processor_in_message_read    : std_logic;
    
    signal message_out_ready    : std_logic;
    signal message_in_available : std_logic;

begin
    ROUTER: hoplite_router_multicast
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS,
            
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MULTICAST_X_COORD       => MULTICAST_X_COORD,
            MULTICAST_Y_COORD       => MULTICAST_Y_COORD,
            USE_MULTICAST           => USE_MULTICAST
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            x_in                    => x_in,
            x_in_valid              => x_in_valid,
            y_in                    => y_in,
            y_in_valid              => y_in_valid,
            pe_in                   => pe_to_network_message,
            pe_in_valid             => pe_to_network_valid,
            pe_backpressure         => pe_backpressure,
            multicast_in            => multicast_in,
            multicast_in_valid      => multicast_in_valid,
            
            
            x_out                   => x_out_d,
            x_out_valid             => x_out_valid_d,
            y_out                   => y_out_d,
            y_out_valid             => y_out_valid_d,
            pe_out                  => network_to_pe_message,
            pe_out_valid            => network_to_pe_valid,
            multicast_out           => multicast_out,
            multicast_out_valid     => multicast_out_valid,
            multicast_backpressure  => multicast_backpressure
        );
    
    -- Connect router ports to node ports
    x_out       <= x_out_d;
    x_out_valid <= x_out_valid_d;
    
    y_out       <= y_out_d;
    y_out_valid <= y_out_valid_d;
    
    -- Network interface controller (FIFO for messages to and from PE)
    router_ready    <= not pe_backpressure;
    pe_ready        <= processor_in_message_read;
    
    NIC: nic_dual
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            
            PE_TO_NETWORK_FIFO_DEPTH    => PE_TO_NETWORK_FIFO_DEPTH,
            NETWORK_TO_PE_FIFO_DEPTH    => NETWORK_TO_PE_FIFO_DEPTH,
           
            USE_INITIALISATION_FILE => False,
            INITIALISATION_FILE     => "none",
            INITIALISATION_LENGTH   => 0
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            -- Messages from PE to network
            from_pe_valid       => pe_message_out_valid,
            from_pe_data        => pe_message_out,
    
            network_ready       => router_ready,
            to_network_valid    => pe_to_network_valid,
            to_network_data     => pe_to_network_message,
            
            pe_to_network_full  => pe_to_network_full,
            pe_to_network_empty => pe_to_network_empty,
    
            -- Messages from network to PE
            from_network_valid  => network_to_pe_valid,
            from_network_data   => network_to_pe_message,
    
            pe_ready            => pe_ready,
            to_pe_valid         => pe_message_in_valid,
            to_pe_data          => pe_message_in,
    
            network_to_pe_full  => network_to_pe_full,
            network_to_pe_empty => network_to_pe_empty
        );

    ENCODER: message_encoder
        generic map (
            COORD_BITS              => COORD_BITS,
            
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MULTICAST_X_COORD       => MULTICAST_X_COORD,
            MULTICAST_Y_COORD       => MULTICAST_Y_COORD,
            
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                         => clk,
            reset_n                     => reset_n,
            
            x_coord_in                  => processor_out_message_x_coord,
            x_coord_in_valid            => processor_out_message_x_coord_valid,
            
            y_coord_in                  => processor_out_message_y_coord,
            y_coord_in_valid            => processor_out_message_y_coord_valid,
            
            multicast_group_in          => processor_out_multicast_group,
            multicast_group_in_valid    => processor_out_multicast_group_valid,

            ready_flag_in                => processor_out_ready_flag,
            ready_flag_in_valid          => processor_out_ready_flag_valid,

            result_flag_in              => processor_out_result_flag,
            result_flag_in_valid        => processor_out_result_flag_valid,

            matrix_type_in              => processor_out_matrix_type,
            matrix_type_in_valid        => processor_out_matrix_type_valid,

            matrix_x_coord_in           => processor_out_matrix_x_coord,
            matrix_x_coord_in_valid     => processor_out_matrix_x_coord_valid,

            matrix_y_coord_in           => processor_out_matrix_y_coord,
            matrix_y_coord_in_valid     => processor_out_matrix_y_coord_valid,

            matrix_element_in           => processor_out_matrix_element,
            matrix_element_in_valid     => processor_out_matrix_element_valid,
            
            packet_complete_in          => processor_out_packet_complete,
            
            packet_out                  => pe_message_out,
            packet_out_valid            => pe_message_out_valid
        );
        
    DECODER: message_decoder
        generic map (
            COORD_BITS              => COORD_BITS,
            
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MULTICAST_X_COORD       => MULTICAST_X_COORD,
            MULTICAST_Y_COORD       => MULTICAST_Y_COORD,
            
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => pe_message_in,
            packet_in_valid     => pe_message_in_valid,
            
            x_coord_out         => open,
            y_coord_out         => open,
            multicast_group_out => processor_in_multicast_group,
            ready_flag_out       => processor_in_ready_flag,
            result_flag_out     => processor_in_result_flag,
            matrix_type_out     => processor_in_matrix_type,
            matrix_x_coord_out  => processor_in_matrix_x_coord,
            matrix_y_coord_out  => processor_in_matrix_y_coord,
            matrix_element_out  => processor_in_matrix_element,

            packet_out_valid    => processor_in_message_valid,
            packet_read         => processor_in_message_read
        );
        
    message_out_ready       <= not pe_to_network_full;
    message_in_available    <= not network_to_pe_empty;
    
    PE: system
        generic map (
            NETWORK_ROWS    => NETWORK_ROWS,
            NETWORK_COLS    => NETWORK_COLS,
            NETWORK_NODES   => NETWORK_NODES,
            COORD_BITS      => COORD_BITS,

            FOX_NETWORK_STAGES  => FOX_NETWORK_STAGES,
            FOX_NETWORK_NODES   => FOX_NETWORK_NODES,

            RESULT_X_COORD  => RESULT_X_COORD,
            RESULT_Y_COORD  => RESULT_Y_COORD,
        
            X_COORD         => X_COORD,
            Y_COORD         => Y_COORD,
            NODE_NUMBER     => NODE_NUMBER,

            FOX_MATRIX_SIZE => FOX_MATRIX_SIZE,
            
            USE_MATRIX_INIT_FILE    => USE_INITIALISATION_FILE,
            
            ROM_X_COORD     => ROM_X_COORD,
            ROM_Y_COORD     => ROM_Y_COORD,
            
            MATRIX_X_OFFSET => MATRIX_X_OFFSET,
            MATRIX_Y_OFFSET => MATRIX_Y_OFFSET,
            
            DIVIDE_ENABLED      => DIVIDE_ENABLED,
            MULTIPLY_ENABLED    => MULTIPLY_ENABLED,
            FIRMWARE            => FIRMWARE,
            MEM_SIZE            => MEM_SIZE
        )
        port map (
            clk                     => clk,
            reset_n                 => reset_n,

            LED                     => LED,

            out_char                => out_char,
            out_char_en             => out_char_en,
            out_char_ready          => out_char_ready,
            
            x_coord_out                 => processor_out_message_x_coord,
            x_coord_out_valid           => processor_out_message_x_coord_valid,
            
            y_coord_out                 => processor_out_message_y_coord,
            y_coord_out_valid           => processor_out_message_y_coord_valid,
            
            multicast_group_out         => processor_out_multicast_group,
            multicast_group_out_valid   => processor_out_multicast_group_valid,

            ready_flag_out               => processor_out_ready_flag,
            ready_flag_out_valid         => processor_out_ready_flag_valid,

            result_flag_out             => processor_out_result_flag,
            result_flag_out_valid       => processor_out_result_flag_valid,

            matrix_type_out             => processor_out_matrix_type,
            matrix_type_out_valid       => processor_out_matrix_type_valid,

            matrix_x_coord_out          => processor_out_matrix_x_coord,
            matrix_x_coord_out_valid    => processor_out_matrix_x_coord_valid,

            matrix_y_coord_out          => processor_out_matrix_y_coord,
            matrix_y_coord_out_valid    => processor_out_matrix_y_coord_valid,

            matrix_element_out          => processor_out_matrix_element,
            matrix_element_out_valid    => processor_out_matrix_element_valid,
            
            packet_complete_out         => processor_out_packet_complete,
            
            message_out_ready       => message_out_ready,

            multicast_group_in      => processor_in_multicast_group,
            ready_flag_in            => processor_in_ready_flag,
            result_flag_in          => processor_in_result_flag,
            matrix_type_in          => processor_in_matrix_type,
            matrix_x_coord_in       => processor_in_matrix_x_coord,
            matrix_y_coord_in       => processor_in_matrix_y_coord,
            matrix_element_in       => processor_in_matrix_element,

            message_in_valid        => processor_in_message_valid,
            message_in_available    => message_in_available,
            message_in_read         => processor_in_message_read,

            out_matrix              => out_matrix,
            out_matrix_en           => out_matrix_en,
            out_matrix_end_row      => out_matrix_end_row,
            out_matrix_end          => out_matrix_end,
            
            trap                    => open
        );

end Behavioral;
