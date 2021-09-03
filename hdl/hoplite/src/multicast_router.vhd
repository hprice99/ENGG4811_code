----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2021 04:02:02 PM
-- Design Name: 
-- Module Name: multicast_router - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- TODO Change multicast_in and multicast_out to pe_to_network and network_to_pe
entity multicast_router is
    Generic (
        BUS_WIDTH               : integer := 32;
        COORD_BITS              : integer := 1;

        MULTICAST_COORD_BITS    : integer := 1;
        MULTICAST_X_COORD       : integer := 1;
        MULTICAST_Y_COORD       : integer := 1
    );
    Port ( 
        clk             : in STD_LOGIC;
        reset_n         : in STD_LOGIC;
        
        -- Input
        x_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_in_valid              : in STD_LOGIC;
        y_in                    : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_in_valid              : in STD_LOGIC;
        multicast_in            : in STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        multicast_in_valid      : in STD_LOGIC;
        multicast_backpressure  : out STD_LOGIC;
        
        -- Output
        x_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        x_out_valid             : out STD_LOGIC;
        y_out                   : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        y_out_valid             : out STD_LOGIC;
        multicast_out           : out STD_LOGIC_VECTOR((BUS_WIDTH-1) downto 0);
        multicast_out_valid     : out STD_LOGIC
    );
end multicast_router;

architecture Behavioral of multicast_router is
    
    signal x_in_d, x_in_q, y_in_d, y_in_q, multicast_in_d : std_logic_vector((BUS_WIDTH-1) downto 0);
    signal sel : std_logic_vector(1 downto 0);
    signal x_next, y_next : std_logic;
    
    signal x_in_valid_d, y_in_valid_d, multicast_in_valid_d : std_logic;
    
    type t_MulticastCoordinate is array (0 to 1) of std_logic_vector((MULTICAST_COORD_BITS-1) downto 0);
    constant X_INDEX    : integer := 0;
    constant Y_INDEX    : integer := 1;
    signal x_in_multicast_dest_d, y_in_multicast_dest_d, multicast_in_multicast_dest_d : t_MulticastCoordinate;
    signal x_in_multicast_dest_q, y_in_multicast_dest_q, multicast_in_multicast_dest_q : t_MulticastCoordinate;
    
    -- Packet destination coordinates
    constant X_INDEX_HEADER_START   : integer := 0;
    constant X_INDEX_HEADER_END     : integer := X_INDEX_HEADER_START + COORD_BITS - 1;
    
    constant Y_INDEX_HEADER_START   : integer := X_INDEX_HEADER_END + 1;
    constant Y_INDEX_HEADER_END     : integer := Y_INDEX_HEADER_START + COORD_BITS - 1;
    
    -- Received packet multicast coordinates
    constant MULTICAST_X_INDEX_HEADER_START  : integer := Y_INDEX_HEADER_END + 1;
    constant MULTICAST_X_INDEX_HEADER_END    : integer := MULTICAST_X_INDEX_HEADER_START + MULTICAST_COORD_BITS - 1;
    
    constant MULTICAST_Y_INDEX_HEADER_START  : integer := MULTICAST_X_INDEX_HEADER_END + 1;
    constant MULTICAST_Y_INDEX_HEADER_END    : integer := MULTICAST_Y_INDEX_HEADER_START + MULTICAST_COORD_BITS - 1;
    
    -- Determine if the packet received is destined for this node
    impure function is_valid_packet_in (packet_in_coord : in t_MulticastCoordinate; 
                                        packet_in_valid : in std_logic) 
                                        return boolean is
        variable is_valid   : boolean;  
    begin
        if (packet_in_valid = '1'
                and to_integer(unsigned(packet_in_coord(X_INDEX))) = MULTICAST_X_COORD 
                and to_integer(unsigned(packet_in_coord(Y_INDEX))) = MULTICAST_Y_COORD) then
            is_valid    := True;   
        else
            is_valid    := False; 
        end if;
        
        return is_valid;
    end function is_valid_packet_in;

begin

    -- Assign multicast coordinates
    x_in_multicast_dest_d(X_INDEX)  <= x_in_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    x_in_multicast_dest_d(Y_INDEX)  <= x_in_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    y_in_multicast_dest_d(X_INDEX)  <= y_in_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    y_in_multicast_dest_d(Y_INDEX)  <= y_in_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    multicast_in_multicast_dest_d(X_INDEX)  <= multicast_in_d(MULTICAST_X_INDEX_HEADER_END downto MULTICAST_X_INDEX_HEADER_START);
    multicast_in_multicast_dest_d(Y_INDEX)  <= multicast_in_d(MULTICAST_Y_INDEX_HEADER_END downto MULTICAST_Y_INDEX_HEADER_START);
    
    x_in_valid_d    <= x_in_valid;
    y_in_valid_d    <= y_in_valid;
    multicast_in_valid_d   <= multicast_in_valid;

    -- Output routing
    sel <= y_in_valid & x_in_valid;
       
    -- Select X output 
    with sel select
        x_in_d <=   multicast_in     when "00",
                    x_in             when "01",
                    multicast_in     when "10",
                    x_in             when others;
               
    -- Select Y output 
    with sel select
        y_in_d <=   multicast_in     when "00",
                    x_in             when "01",
                    y_in             when "10",
                    y_in             when others;
               
    multicast_in_d    <= multicast_in;

    -- Apply backpressure to the multicast cluster
    with sel select
        multicast_backpressure <=   '0' when "00",
                                    '1' when "10",
                                    '1' when others;
    
    OUTPUT_FF: process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_in_q         <= (others => '0');
                y_in_q         <= (others => '0');
                
                multicast_out           <= (others => '0');
                multicast_out_valid     <= '0';
            else
                x_in_q <= x_in_d;
                y_in_q <= y_in_d;
               
                if (is_valid_packet_in(multicast_in_multicast_dest_d, multicast_in_valid) = True) then
                    multicast_out_valid    <= '1'; 
                    multicast_out          <= multicast_in_d;
               
                elsif (is_valid_packet_in(x_in_multicast_dest_d, x_in_valid) = True) then
                    multicast_out_valid    <= '1'; 
                    multicast_out          <= x_in_d;
                    
                elsif (is_valid_packet_in(y_in_multicast_dest_d, y_in_valid) = True) then
                    multicast_out_valid    <= '1';
                    multicast_out          <= y_in_d;
                
                else
                    multicast_out_valid    <= '0';
                    
                end if;
            end if;
        end if;
    end process OUTPUT_FF;
        
    -- Output to X and Y links
    x_out <= x_in_q;
    y_out <= y_in_q;

     NEXT_VALID: process (x_in_valid_d, y_in_valid_d, x_in_multicast_dest_d, y_in_multicast_dest_d, multicast_in_valid_d, multicast_in_multicast_dest_d)
     begin
        x_next  <= '0';
        y_next  <= '0';
     
        if (x_in_valid_d = '1' and is_valid_packet_in(x_in_multicast_dest_d, x_in_valid) = False) then
            x_next <= '1';
        elsif (multicast_in_valid_d = '1' and is_valid_packet_in(multicast_in_multicast_dest_d, multicast_in_valid_d) = True) then
            x_next <= '0';
        else
            x_next <= multicast_in_valid_d;
        end if;
        
        -- Switch y_out to act as multicast_out
        if (x_in_valid_d = '1' and is_valid_packet_in(x_in_multicast_dest_d, x_in_valid_d) = True) then
            -- Both x_in and y_in are destined for the PE, so y_in must be deflected
            if (y_in_valid_d = '1' and is_valid_packet_in(y_in_multicast_dest_d, y_in_valid_d) = True) then
                y_next <= '1';
            else
                y_next <= '0';
            end if;
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_multicast_dest_d, y_in_valid_d) = True) then
            y_next <= '0';
            
        elsif (y_in_valid_d = '1' and is_valid_packet_in(y_in_multicast_dest_d, y_in_valid_d) = False) then
            y_next <= '1';
            
        elsif (x_in_valid_d = '1' and is_valid_packet_in(x_in_multicast_dest_d, x_in_valid_d) = False) then
            y_next <= '1';
        
        elsif (multicast_in_valid_d = '1' and is_valid_packet_in(multicast_in_multicast_dest_d, multicast_in_valid_d) = True) then
            y_next <= '0';
            
        else
            y_next <= multicast_in_valid_d;
            
        end if;
    end process NEXT_VALID;
    
    -- Valid signal routing    
    OUTPUT_VALID_FF: process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                x_out_valid <= '0';
                y_out_valid <= '0';
            else
                -- Multicast not possible
                if (y_in_valid = '1') then
                    x_out_valid <= x_next;
                    y_out_valid <= y_next;
                elsif (to_integer(unsigned(x_in_multicast_dest_d(X_INDEX))) /= MULTICAST_X_COORD) then
                    x_out_valid <= x_next;
                    y_out_valid <= '0';
                elsif (to_integer(unsigned(x_in_multicast_dest_d(Y_INDEX))) /= MULTICAST_Y_COORD) then
                    x_out_valid <= '0';
                    y_out_valid <= y_next;
                else
                    x_out_valid <= x_next;
                    y_out_valid <= y_next;
                end if;
            end if;
        end if;
    end process OUTPUT_VALID_FF;
    
end Behavioral;
