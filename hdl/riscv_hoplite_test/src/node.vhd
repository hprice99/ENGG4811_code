library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

entity node is
    Generic (
        NETWORK_ROWS    : integer := 2;
        NETWORK_COLS    : integer := 2;   
        NETWORK_NODES   : integer := 4;
    
        X_COORD         : integer := 0;
        Y_COORD         : integer := 0;
        NODE_NUMBER     : integer := 0;
        
        COORD_BITS      : integer := 2;
        MESSAGE_BITS    : integer := 32;
        BUS_WIDTH       : integer := 8;
        
        DIVIDE_ENABLED     : std_logic := '0';
        MULTIPLY_ENABLED   : std_logic := '1';
        FIRMWARE           : string    := "firmware.hex";
        MEM_SIZE           : integer   := 4096
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        switch              : in std_logic;
        LED                 : out std_logic_vector((NETWORK_NODES-1) downto 0);
        
        x_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        x_in_valid          : in std_logic;
        y_in                : in std_logic_vector((BUS_WIDTH-1) downto 0);
        y_in_valid          : in std_logic;
        
        x_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        x_out_valid         : out std_logic;
        y_out               : out std_logic_vector((BUS_WIDTH-1) downto 0);
        y_out_valid         : out std_logic
    );
end node;

architecture Behavioral of node is

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
    
    component nic_dual
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
    
            network_to_pe_full  : out std_logic;
            network_to_pe_empty : out std_logic
        );
    end component nic_dual;
    
    component message_encoder
        generic (
            COORD_BITS      : integer := 2;
            MESSAGE_BITS    : integer := 32;
            BUS_WIDTH       : integer := 36
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            x_coord_in          : in std_logic_vector((COORD_BITS-1) downto 0);
            x_coord_in_valid    : in std_logic;
            
            y_coord_in          : in std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_in_valid    : in std_logic;
            
            message_in          : in std_logic_vector((MESSAGE_BITS-1) downto 0);
            message_in_valid    : in std_logic;
            
            packet_in_complete  : in std_logic;
            
            packet_out          : out std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_out_valid    : out std_logic
        );
    end component message_encoder;
    
    component message_decoder
        generic (
            COORD_BITS      : integer := 2;
            MESSAGE_BITS    : integer := 32;
            BUS_WIDTH       : integer := 36
        );
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;
            
            packet_in           : in std_logic_vector((BUS_WIDTH-1) downto 0);
            packet_in_valid     : in std_logic;
            
            x_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_out         : out std_logic_vector((COORD_BITS-1) downto 0);
            message_out         : out std_logic_vector((MESSAGE_BITS-1) downto 0);
            packet_out_valid    : out std_logic;
            
            packet_read         : in std_logic
        );
    end component message_decoder;
    
    component system
        generic (
            NETWORK_ROWS    : integer := 2;
            NETWORK_COLS    : integer := 2;   
            NETWORK_NODES   : integer := 4;
            COORD_BITS      : integer := 1;
        
            X_COORD         : integer := 0;
            Y_COORD         : integer := 0;
            NODE_NUMBER     : integer := 0;
            
            DIVIDE_ENABLED     : std_logic := '0';
            MULTIPLY_ENABLED   : std_logic := '1';
            FIRMWARE           : string    := "firmware.hex";
            MEM_SIZE           : integer   := 4096
        );
        port (
            clk                     : in std_logic;
            reset_n                 : in std_logic;
            
            switch                  : in std_logic;
            LED                     : out std_logic_vector((NETWORK_NODES-1) downto 0);
            
            x_coord_out             : out std_logic_vector((COORD_BITS-1) downto 0);
            x_coord_out_valid       : out std_logic;
            
            y_coord_out             : out std_logic_vector((COORD_BITS-1) downto 0);
            y_coord_out_valid       : out std_logic;
            
            message_out             : out std_logic_vector(31 downto 0); 
            message_out_valid       : out std_logic;
            
            packet_out_complete     : out std_logic;
            
            message_out_ready       : in std_logic;
            
            message_in              : in std_logic_vector(31 downto 0);
            message_in_valid        : in std_logic; 
            message_in_available    : in std_logic;
            message_in_read         : out std_logic;
            
            trap                    : out std_logic
        );
    end component system;
    
    component pipeline
        generic (
            STAGES  : integer := 10
        );
        port (
            clk     : in std_logic;
            d_in    : in std_logic;
            d_out   : out std_logic
        );
    end component pipeline;
    
    signal switch_pipelined         : std_logic;
    constant SWITCH_PIPELINE_STAGES : integer := 30;
    
    constant FIFO_DEPTH             : integer := 32;
    
    -- Messages from PE to network
    signal pe_message_out       : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : std_logic;
    
    signal pe_to_network_message    : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal pe_to_network_valid      : std_logic;
    
    signal pe_backpressure      : std_logic;
    signal router_ready         : std_logic;
    
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
    
    signal processor_out_message        : std_logic_vector((MESSAGE_BITS-1) downto 0);
    signal processor_out_message_valid  : std_logic;
    
    signal processor_out_packet_complete    : std_logic;
    
    -- Message decoder signals
    signal processor_in_message         : std_logic_vector((MESSAGE_BITS-1) downto 0);
    signal processor_in_message_valid   : std_logic;
    signal processor_in_message_read    : std_logic;
    
    signal message_out_ready    : std_logic;
    signal message_in_available : std_logic;

begin
    SWITCH_PIPELINE : pipeline
        generic map (
            STAGES  => SWITCH_PIPELINE_STAGES
        )
        port map (
            clk         => clk,
            d_in        => switch,
            d_out       => switch_pipelined
        );
    
    ROUTER: hoplite_router_unicast
        generic map (
            BUS_WIDTH   => BUS_WIDTH,
            X_COORD     => X_COORD,
            Y_COORD     => Y_COORD,
            COORD_BITS  => COORD_BITS
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            x_in                => x_in,
            x_in_valid          => x_in_valid,
            y_in                => y_in,
            y_in_valid          => y_in_valid,
            pe_in               => pe_to_network_message,
            pe_in_valid         => pe_to_network_valid,
            
            x_out               => x_out_d,
            x_out_valid         => x_out_valid_d,
            y_out               => y_out_d,
            y_out_valid         => y_out_valid_d,
            pe_out              => network_to_pe_message,
            pe_out_valid        => network_to_pe_valid,
            pe_backpressure     => pe_backpressure
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
            FIFO_DEPTH  => FIFO_DEPTH
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
            COORD_BITS      => COORD_BITS,
            MESSAGE_BITS    => MESSAGE_BITS,
            BUS_WIDTH       => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            x_coord_in          => processor_out_message_x_coord,
            x_coord_in_valid    => processor_out_message_x_coord_valid,
            
            y_coord_in          => processor_out_message_y_coord,
            y_coord_in_valid    => processor_out_message_y_coord_valid,
            
            message_in          => processor_out_message,
            message_in_valid    => processor_out_message_valid,
            
            packet_in_complete  => processor_out_packet_complete,
            
            packet_out          => pe_message_out,
            packet_out_valid    => pe_message_out_valid
        );
        
    DECODER: message_decoder
        generic map (
            COORD_BITS      => COORD_BITS,
            MESSAGE_BITS    => MESSAGE_BITS,
            BUS_WIDTH       => BUS_WIDTH
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            
            packet_in           => pe_message_in,
            packet_in_valid     => pe_message_in_valid,
            
            x_coord_out         => open,
            y_coord_out         => open,
            message_out         => processor_in_message,
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
        
            X_COORD         => X_COORD,
            Y_COORD         => Y_COORD,
            NODE_NUMBER     => NODE_NUMBER,
            
            DIVIDE_ENABLED      => DIVIDE_ENABLED,
            MULTIPLY_ENABLED    => MULTIPLY_ENABLED,
            FIRMWARE            => FIRMWARE,
            MEM_SIZE            => MEM_SIZE
        )
        port map (
            clk                     => clk,
            reset_n                 => reset_n,
            
            switch                  => switch_pipelined,
            LED                     => LED,
            
            x_coord_out             => processor_out_message_x_coord,
            x_coord_out_valid       => processor_out_message_x_coord_valid,
            
            y_coord_out             => processor_out_message_y_coord,
            y_coord_out_valid       => processor_out_message_y_coord_valid,
            
            message_out             => processor_out_message,
            message_out_valid       => processor_out_message_valid,
            
            packet_out_complete     => processor_out_packet_complete,
            
            message_out_ready       => message_out_ready,
            
            message_in              => processor_in_message,
            message_in_valid        => processor_in_message_valid,
            message_in_available    => message_in_available,
            message_in_read         => processor_in_message_read,
            
            trap                    => open
        );

end Behavioral;
