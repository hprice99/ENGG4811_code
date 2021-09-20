----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/04/2021 07:50:00 PM
-- Design Name: 
-- Module Name: node_switch - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;

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
        ROM_ADDRESS_WIDTH       : integer := 6
    );
    Port (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        rom_read_complete   : out std_logic;

        x_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid          : in STD_LOGIC;
        y_in                : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid          : in STD_LOGIC;
        
        x_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid         : out STD_LOGIC;
        y_out               : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid         : out STD_LOGIC
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
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            
            -- Input (messages received by router)
            x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid      : in STD_LOGIC;
            
            y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid      : in STD_LOGIC;
            
            pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in STD_LOGIC;
            pe_backpressure : out STD_LOGIC;
            
            multicast_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            multicast_in_valid      : in STD_LOGIC;

            -- Output (messages sent out of router)
            x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid     : out STD_LOGIC;
            
            y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid     : out STD_LOGIC;
            
            pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out STD_LOGIC;
            
            multicast_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            multicast_out_valid     : out STD_LOGIC;
            multicast_backpressure  : in STD_LOGIC
        );
    end component hoplite_router_multicast;

    component nic_dual
        generic (
            BUS_WIDTH   : integer := 32;
            FIFO_DEPTH  : integer := 64;
            
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

    component rom is
        generic (
            BUS_WIDTH       : integer := 32;
            ROM_DEPTH       : integer := 64;
            ADDRESS_WIDTH   : integer := 6;
            
            INITIALISATION_FILE : string    := "none"
        );
        port (
            clk         : in std_logic;
    
            read_en     : in std_logic;
            read_addr   : in std_logic_vector((ADDRESS_WIDTH-1) downto 0);
            read_data   : out std_logic_vector((BUS_WIDTH-1) downto 0)
        );
    end component rom;
    
    -- Messages from PE to network
    signal pe_message_out       : STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
    signal pe_message_out_valid : STD_LOGIC;
    
    signal pe_to_network_message    : STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
    signal pe_to_network_valid      : STD_LOGIC;
    
    signal pe_backpressure          : STD_LOGIC;
    signal router_ready             : STD_LOGIC;
    
    signal pe_to_network_full, pe_to_network_empty   : STD_LOGIC;
    
    -- Packets routed out
    signal x_out_d, y_out_d             : STD_LOGIC_VECTOR ((BUS_WIDTH-1) downto 0);
    signal x_out_valid_d, y_out_valid_d : STD_LOGIC;
    
    -- ROM control signals
    signal rom_read_en          : std_logic;
    signal rom_read_address     : std_logic_vector((ROM_ADDRESS_WIDTH-1) downto 0);
    signal rom_read_data        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal rom_read_data_valid  : std_logic;

    signal rom_read_started : std_logic;

    signal read_address     : integer;

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
            pe_out                  => open,
            pe_out_valid            => open,
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
            FIFO_DEPTH  => FIFO_DEPTH,
           
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
            from_network_valid  => '0',
            from_network_data   => (others => '0'),
    
            pe_ready            => '0',
            to_pe_valid         => open,
            to_pe_data          => open,
    
            network_to_pe_full  => open,
            network_to_pe_empty => open
        );

    pe_message_out_valid    <= rom_read_data_valid;
    pe_message_out          <= rom_read_data;

    ROM_MEMORY: rom 
        generic map (
            BUS_WIDTH       => BUS_WIDTH,
            ROM_DEPTH       => ROM_DEPTH,
            ADDRESS_WIDTH   => ROM_ADDRESS_WIDTH,
            
            INITIALISATION_FILE => MATRIX_FILE
        )
        port map (
            clk         => clk,
            
            read_en     => rom_read_en,
            read_addr   => rom_read_address,
            read_data   => rom_read_data
        );
        
    rom_read_address    <= std_logic_vector(to_unsigned(read_address, ROM_ADDRESS_WIDTH));

    ROM_READ: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                rom_read_en             <= '0';
                rom_read_data_valid     <= '0';
                read_address            <= 0;
                rom_read_complete       <= '0';
                rom_read_started        <= '0';
            else
                rom_read_data_valid   <= rom_read_en;
            
                if (rom_read_en = '0' and read_address < ROM_DEPTH and pe_to_network_full = '0') then
                    rom_read_en <= '1';
                elsif (read_address < ROM_DEPTH and pe_to_network_full = '0') then
                    rom_read_en     <= '1';
                    read_address    <= read_address + 1;
                else
                    rom_read_en     <= '0';
                end if;
                
                if (read_address = ROM_DEPTH) then
                    rom_read_complete   <= '1';
                else
                    rom_read_complete   <= '0';
                end if;
            end if;
        end if;
    end process ROM_READ;

end Behavioral;
