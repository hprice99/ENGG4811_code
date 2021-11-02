library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.math_functions.all;
use xil_defaultlib.packet_defs.all;
use xil_defaultlib.fox_defs.all;

entity ROM_burst is
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
end ROM_burst;

architecture Behavioral of ROM_burst is

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

    message_out_valid   <= rom_read_data_valid;
    message_out         <= rom_read_data;

    ROM_BURST_READY_GEN: if (USE_BURST = True) generate
        node_coord_received <= get_matrix_coord(message_in);
        node_ready_received <= get_ready_flag(message_in);
        
        NODE_READY_X_GEN: for x in 0 to (FOX_NETWORK_STAGES-1) generate
            NODE_READY_Y_GEN: for y in 0 to (FOX_NETWORK_STAGES-1) generate
                NODE_READY_PROC: process (clk)
                begin
                    if (rising_edge(clk)) then
                        if (reset_n = '0' or rom_burst_read = BURST_LENGTH) then
                            receiver_nodes_ready(x, y)  <= '0';
                        else
                            if (message_in_valid = '1') then
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
                        message_out_ready = '1') then
                    rom_read_en <= '1';
                    rom_burst_read  <= rom_burst_read + 1;
                    
                elsif (read_address < ROM_DEPTH and 
                        rom_read_ready = '1' and ((USE_BURST = False) or (USE_BURST = True and rom_burst_read < BURST_LENGTH)) and
                        message_out_ready = '1') then
                    rom_read_en     <= '1';
                    
                    read_address    <= read_address + 1;
                    rom_burst_read  <= rom_burst_read + 1;
                    
                elsif (read_address < ROM_DEPTH and 
                        rom_read_ready = '1' and ((USE_BURST = True and rom_burst_read = BURST_LENGTH))) then
                    rom_read_en         <= '0';

                    read_address        <= read_address + 1;
                    rom_burst_read      <= 0;
                    
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
