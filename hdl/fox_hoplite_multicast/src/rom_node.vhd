library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;

entity rom_node is
    Generic (   
        -- Node parameters
        X_COORD         : integer := 0;
        Y_COORD         : integer := 0;
        
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
end rom_node;

architecture Behavioral of rom_node is

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

    component ROM_burst is
        Generic (   
            -- Packet parameters
            COORD_BITS              : integer := 2;
            MULTICAST_GROUP_BITS    : integer := 1;
            MULTICAST_COORD_BITS    : integer := 1;
            MATRIX_TYPE_BITS        : integer := 1;
            MATRIX_COORD_BITS       : integer := 8;
            MATRIX_ELEMENT_BITS     : integer := 32;
            BUS_WIDTH               : integer := 56;
    
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
    
            message_in          : in std_logic_vector((BUS_WIDTH-1) downto 0);
            message_in_valid    : in std_logic;
            
            message_out         : out std_logic_vector((BUS_WIDTH-1) downto 0);
            message_out_valid   : out std_logic;
            message_out_ready   : in std_logic
        );
    end component ROM_burst;
    
    -- Messages from PE to network
    signal pe_message_out       : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : std_logic;
    
    signal pe_to_network_message    : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_to_network_valid      : std_logic;
    
    signal pe_backpressure          : std_logic;
    signal router_ready             : std_logic;
    
    signal pe_to_network_full, pe_to_network_empty   : std_logic;
    
    -- Packets routed out
    signal x_out_d, y_out_d             : std_logic_vector ((BUS_WIDTH-1) downto 0);
    signal x_out_valid_d, y_out_valid_d : std_logic;
    
    -- Messages from network to PE
    signal from_network_valid   : std_logic;
    signal from_network_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal to_pe_valid          : std_logic;
    signal to_pe_data           : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal network_to_pe_full, network_to_pe_empty  : std_logic;
    
    signal rom_receive_ready    : std_logic;
    
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
            USE_MULTICAST           => False
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
            multicast_in            => (others => '0'),
            multicast_in_valid      => '0',
            
            x_out                   => x_out_d,
            x_out_valid             => x_out_valid_d,
            y_out                   => y_out_d,
            y_out_valid             => y_out_valid_d,
            pe_out                  => from_network_data,
            pe_out_valid            => from_network_valid,
            multicast_out           => open,
            multicast_out_valid     => open,
            multicast_backpressure  => '0'
        );
    
    -- Connect router ports to node ports
    x_out       <= x_out_d;
    x_out_valid <= x_out_valid_d;
    
    y_out       <= y_out_d;
    y_out_valid <= y_out_valid_d;
    
    -- Network interface controller (FIFO for messages to and from PE)
    router_ready    <= not pe_backpressure;
    
    NIC: nic_dual
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            
            PE_TO_NETWORK_FIFO_DEPTH    => FIFO_DEPTH,
            NETWORK_TO_PE_FIFO_DEPTH    => 4,
           
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
            from_network_valid  => from_network_valid,
            from_network_data   => from_network_data,
   
            pe_ready            => '1',
            to_pe_valid         => to_pe_valid,
            to_pe_data          => to_pe_data,
    
            network_to_pe_full  => network_to_pe_full,
            network_to_pe_empty => network_to_pe_empty
        );

    rom_receive_ready   <= not pe_to_network_full;

    BURST_ROM: rom_burst
        generic map (
            COORD_BITS              => COORD_BITS,
            MULTICAST_GROUP_BITS    => MULTICAST_GROUP_BITS,
            MULTICAST_COORD_BITS    => MULTICAST_COORD_BITS,
            MATRIX_TYPE_BITS        => MATRIX_TYPE_BITS,
            MATRIX_COORD_BITS       => MATRIX_COORD_BITS,
            MATRIX_ELEMENT_BITS     => MATRIX_ELEMENT_BITS,
            BUS_WIDTH               => BUS_WIDTH,
    
            USE_INITIALISATION_FILE => USE_INITIALISATION_FILE,
            MATRIX_FILE             => MATRIX_FILE,
            ROM_DEPTH               => ROM_DEPTH,
            ROM_ADDRESS_WIDTH       => ROM_ADDRESS_WIDTH,
    
            USE_BURST               => USE_BURST,
            BURST_LENGTH            => BURST_LENGTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            rom_read_complete   => rom_read_complete,
    
            message_in          => to_pe_data,
            message_in_valid    => to_pe_valid,
            
            message_out         => pe_message_out,
            message_out_valid   => pe_message_out_valid,
            message_out_ready   => rom_receive_ready
        );

end Behavioral;
