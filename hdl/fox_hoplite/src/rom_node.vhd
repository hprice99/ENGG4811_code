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
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;

entity rom_node is
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

    component hoplite_router
        generic (
            BUS_WIDTH   : integer := 32;
            X_COORD     : integer := 0;
            Y_COORD     : integer := 0;
            COORD_BITS  : integer := 1
        );
        port (
            clk             : in STD_LOGIC;
            reset_n         : in STD_LOGIC;
            
            x_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_in_valid      : in STD_LOGIC;
            y_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_in_valid      : in STD_LOGIC;
            pe_in           : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_in_valid     : in STD_LOGIC;
            
            x_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            x_out_valid     : out STD_LOGIC;
            y_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            y_out_valid     : out STD_LOGIC;
            pe_out          : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
            pe_out_valid    : out STD_LOGIC;
            pe_backpressure : out STD_LOGIC
        );
    end component hoplite_router;

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
    
    -- Messages from network to PE
    signal from_network_valid   : std_logic;
    signal from_network_data    : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal to_pe_valid          : std_logic;
    signal to_pe_data           : std_logic_vector((BUS_WIDTH-1) downto 0);
    
    signal network_to_pe_full, network_to_pe_empty  : std_logic;
    
    -- ROM control signals
    signal rom_read_en          : std_logic;
    signal rom_read_address     : std_logic_vector((ROM_ADDRESS_WIDTH-1) downto 0);
    signal rom_read_data        : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal rom_read_data_valid  : std_logic;

    signal rom_read_started : std_logic;
    signal read_address     : integer;
    signal rom_burst_read   : integer;

    -- Node ready signals
    signal node_coord_received  : t_MatrixCoordinate;
    signal node_ready_received  : std_logic;
    
    type t_NodesReady is array (0 to (FOX_NETWORK_STAGES-1), 0 to (FOX_NETWORK_STAGES-1)) of std_logic;
    
    signal receiver_nodes_ready : t_NodesReady;
    signal rom_read_ready   : std_logic;

    function all_nodes_ready (nodes_ready : in t_NodesReady) return std_logic is
        variable all_ready  : std_logic;
    begin
        all_ready   := '1';
        
        for row in 0 to (FOX_NETWORK_STAGES-1) loop
            for col in 0 to (FOX_NETWORK_STAGES-1) loop
                all_ready   := all_ready and nodes_ready(col, row);
            end loop;
        end loop;
    
        return all_ready;
    end function all_nodes_ready;


begin

    assert ((USE_BURST = False) or (USE_BURST = True and BURST_LENGTH > 0)) report "USE_BURST must be False or BURST_LENGTH must be positive" severity failure;

    ROUTER: hoplite_router
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
            pe_backpressure     => pe_backpressure,
            
            x_out               => x_out_d,
            x_out_valid         => x_out_valid_d,
            y_out               => y_out_d,
            y_out_valid         => y_out_valid_d,
            pe_out              => from_network_data,
            pe_out_valid        => from_network_valid
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

    pe_message_out_valid    <= rom_read_data_valid;
    pe_message_out          <= rom_read_data;

    ROM_BURST_READY_GEN: if (USE_BURST = True) generate
        node_coord_received <= get_matrix_coord(to_pe_data);
        node_ready_received <= get_done_flag(to_pe_data);
        
        NODE_READY_X_GEN: for x in 0 to (FOX_NETWORK_STAGES-1) generate
            NODE_READY_Y_GEN: for y in 0 to (FOX_NETWORK_STAGES-1) generate
                NODE_READY_PROC: process (clk)
                begin
                    if (rising_edge(clk)) then
                        if (reset_n = '0' or rom_burst_read = BURST_LENGTH) then
                            receiver_nodes_ready(x, y)  <= '0';
                        else
                            if (to_pe_valid = '1') then
                                if (to_integer(unsigned(node_coord_received(X_INDEX))) = x and 
                                        to_integer(unsigned(node_coord_received(Y_INDEX))) = y) then
                                    receiver_nodes_ready(x, y)  <= node_ready_received;
                                end if;
                            end if;
                        end if;
                    end if;
                end process NODE_READY_PROC;
            end generate NODE_READY_Y_GEN;
        end generate NODE_READY_X_GEN;
    
        rom_read_ready  <= all_nodes_ready(receiver_nodes_ready);
    end generate ROM_BURST_READY_GEN;

    ROM_NO_BURST_READY_GEN: if (USE_BURST = False) generate
        rom_read_ready  <= '1';
    end generate ROM_NO_BURST_READY_GEN;

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
                rom_burst_read          <= 0;
                
                rom_read_complete       <= '0';
                rom_read_started        <= '0';
            else
                rom_read_data_valid   <= rom_read_en;
            
                if (rom_read_en = '0' and read_address < ROM_DEPTH and 
                        rom_read_ready = '1' and ((USE_BURST = False) or (USE_BURST = True and rom_burst_read < BURST_LENGTH)) and 
                        pe_to_network_full = '0') then
                    rom_read_en <= '1';
                    rom_burst_read  <= rom_burst_read + 1;
                    
                elsif (read_address < ROM_DEPTH and 
                        rom_read_ready = '1' and ((USE_BURST = False) or (USE_BURST = True and rom_burst_read < BURST_LENGTH)) and
                        pe_to_network_full = '0') then
                    rom_read_en     <= '1';
                    
                    read_address    <= read_address + 1;
                    rom_burst_read  <= rom_burst_read + 1;
                    
                elsif (read_address < ROM_DEPTH and 
                        rom_read_ready = '1' and ((USE_BURST = True and rom_burst_read = BURST_LENGTH))) then    
                    rom_read_en         <= '0';
                    rom_burst_read      <= 0;
                    read_address        <= read_address + 1;
                    
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
